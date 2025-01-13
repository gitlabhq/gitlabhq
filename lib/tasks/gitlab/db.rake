# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

def each_database(databases, include_geo: false)
  ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database|
    next if database == 'embedding'
    next if database == 'jh'
    next if !include_geo && database == 'geo'

    yield database
  end
end

namespace :gitlab do
  namespace :db do
    desc 'GitLab | DB | Manually insert schema migration version on all configured databases'
    task :mark_migration_complete, [:version] => :environment do |_, args|
      mark_migration_complete(args[:version])
    end

    desc 'Gitlab | DB | Troubleshoot issues with the database'
    task sos: :environment do
      Gitlab::Database::Sos.run("tmp/sos")
    end

    namespace :mark_migration_complete do
      each_database(databases) do |database_name|
        desc "Gitlab | DB | Manually insert schema migration version on #{database_name} database"
        task database_name, [:version] => :environment do |_, args|
          mark_migration_complete(args[:version], only_on: database_name)
        end
      end
    end

    def mark_migration_complete(version, only_on: nil)
      if version.to_i == 0
        puts Rainbow('Must give a version argument that is a non-zero integer').red
        exit 1
      end

      Gitlab::Database::EachDatabase.each_connection(only: only_on) do |connection, name|
        connection.execute("INSERT INTO schema_migrations (version) VALUES (#{connection.quote(version)})")

        puts Rainbow("Successfully marked '#{version}' as complete on database #{name}").green
      rescue ActiveRecord::RecordNotUnique
        puts Rainbow("Migration version '#{version}' is already marked complete on database #{name}").yellow
      end
    end

    desc 'GitLab | DB | Drop all tables on all configured databases'
    task drop_tables: :environment do
      drop_tables
    end

    namespace :drop_tables do
      each_database(databases) do |database_name|
        desc "GitLab | DB | Drop all tables on the #{database_name} database"
        task database_name => :environment do
          drop_tables(only_on: database_name)
        end
      end
    end

    def drop_tables(only_on: nil)
      Gitlab::Database::EachDatabase.each_connection(only: only_on) do |connection, name|
        # In PostgreSQLAdapter, data_sources returns both views and tables, so use tables instead
        tables = connection.tables

        # Views that are dependencies to PG_EXTENSION (like pg_stat_statements) should be ignored
        ignored_views = Gitlab::Database::PgDepend.using_connection(connection) do
          Gitlab::Database::PgDepend.from_pg_extension('VIEW').pluck('relname')
        end

        # Removes the entry from the array
        tables.delete 'schema_migrations'
        # Truncate schema_migrations to ensure migrations re-run
        connection.execute('TRUNCATE schema_migrations') if connection.table_exists? 'schema_migrations'

        # Drop any views
        (connection.views - ignored_views).each do |view|
          connection.execute("DROP VIEW IF EXISTS #{connection.quote_table_name(view)} CASCADE")
        end

        # Drop tables with cascade to avoid dependent table errors
        # PG: http://www.postgresql.org/docs/current/static/ddl-depend.html
        # Add `IF EXISTS` because cascade could have already deleted a table.
        tables.each { |t| connection.execute("DROP TABLE IF EXISTS #{connection.quote_table_name(t)} CASCADE") }

        # Drop all extra schema objects GitLab owns
        Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
          connection.execute("DROP SCHEMA IF EXISTS #{connection.quote_table_name(schema)} CASCADE")
        end
      end
    end

    desc 'GitLab | DB | Configures the database by running migrate, or by loading the schema and seeding if needed'
    task configure: :environment do
      configure_pg_databases
      configure_clickhouse_databases
    end

    def configure_pg_databases
      databases_with_tasks = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)

      databases_loaded = []

      if databases_with_tasks.size == 1
        return unless databases_with_tasks.first.name == 'main'

        connection = Gitlab::Database.database_base_models['main'].connection
        databases_loaded << configure_database(connection)
      else
        Gitlab::Database.database_base_models_with_gitlab_shared.each do |name, model|
          next unless databases_with_tasks.any? { |db_with_tasks| db_with_tasks.name == name }

          databases_loaded << configure_database(model.connection, database_name: name)
        end
      end

      return unless databases_loaded.present? && databases_loaded.all?

      alter_cell_sequences_range

      Rake::Task["gitlab:db:lock_writes"].invoke
      Rake::Task['db:seed_fu'].invoke
    end

    def configure_clickhouse_databases
      Rake::Task['gitlab:clickhouse:migrate'].invoke(true)
    end

    def configure_database(connection, database_name: nil)
      database_name = ":#{database_name}" if database_name
      load_database = connection.tables.count <= 1

      ActiveRecord::Base.connection_handler.clear_all_connections!(:all)

      if load_database
        puts "Running db:schema:load#{database_name} rake task"
        Gitlab::Database.add_post_migrate_path_to_rails(force: true)
        Rake::Task["db:schema:load#{database_name}"].invoke
      else
        puts "Running db:migrate#{database_name} rake task"
        Rake::Task["db:migrate#{database_name}"].invoke
      end

      load_database
    end

    def alter_cell_sequences_range
      return unless Gitlab.config.topology_service_enabled?

      return puts "Skipping altering cell sequences range" if Gitlab.config.skip_sequence_alteration?

      sequence_range = Gitlab::TopologyServiceClient::CellService.new.cell_sequence_range

      return unless sequence_range.present?

      puts "Running gitlab:db:alter_cell_sequences_range rake task with (#{sequence_range.join(', ')})"
      Rake::Task["gitlab:db:alter_cell_sequences_range"].invoke(*sequence_range)
    end

    desc "Clear all connections"
    task :clear_all_connections do
      ActiveRecord::Base.connection_handler.clear_all_connections!(:all)
    end

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      Rake::Task["db:test:purge:#{name}"].enhance(['gitlab:db:clear_all_connections'])
    end

    desc 'GitLab | DB | Run database migrations and print `unattended_migrations_completed` if action taken'
    task unattended: :environment do
      no_database = !ActiveRecord::Base.connection.schema_migration.table_exists?
      needs_migrations = ActiveRecord::Base.connection.migration_context.needs_migration?

      if no_database || needs_migrations
        Rake::Task['gitlab:db:configure'].invoke
        puts "unattended_migrations_completed"
      else
        puts "unattended_migrations_static"
      end
    end

    desc 'This adjusts and cleans db/structure.sql - it runs after db:schema:dump'
    task :clean_structure_sql do |task_name|
      ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each do |db_config|
        structure_file = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(db_config)

        schema = File.read(structure_file)

        File.open(structure_file, 'wb+') do |io|
          Gitlab::Database::SchemaCleaner.new(schema).clean(io)
        end
      end

      # Allow this task to be called multiple times, as happens when running db:migrate:redo
      Rake::Task[task_name].reenable
    end

    # Inform Rake that custom tasks should be run every time rake db:schema:dump is run
    Rake::Task['db:schema:dump'].enhance do
      Rake::Task['gitlab:db:clean_structure_sql'].invoke
    end

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      # Inform Rake that custom tasks should be run every time rake db:schema:dump is run
      Rake::Task["db:schema:dump:#{name}"].enhance do
        Rake::Task['gitlab:db:clean_structure_sql'].invoke
      end
    end

    desc 'Create missing dynamic database partitions'
    task create_dynamic_partitions: :environment do
      Gitlab::Database::Partitioning.sync_partitions
    end

    namespace :create_dynamic_partitions do
      each_database(databases) do |database_name|
        desc "Create missing dynamic database partitions on the #{database_name} database"
        task database_name => :environment do
          Gitlab::Database::Partitioning.sync_partitions(only_on: database_name)
        end
      end
    end

    # This is targeted towards deploys and upgrades of GitLab.
    # Since we're running migrations already at this time,
    # we also check and create partitions as needed here.
    Rake::Task['db:migrate'].enhance do
      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    # We'll temporarily skip this enhancement for geo, since in some situations we
    # wish to setup the geo database before the other databases have been setup,
    # and partition management attempts to connect to the main database.
    each_database(databases) do |database_name|
      Rake::Task["db:migrate:#{database_name}"].enhance do
        Rake::Task["gitlab:db:create_dynamic_partitions:#{database_name}"].invoke
      end
    end

    # When we load the database schema from db/structure.sql
    # we don't have any dynamic partitions created. We don't really need to
    # because application initializers/sidekiq take care of that, too.
    # However, the presence of partitions for a table has influence on their
    # position in db/structure.sql (which is topologically sorted).
    #
    # Other than that it's helpful to create partitions early when bootstrapping
    # a new installation.
    Rake::Task['db:schema:load'].enhance do
      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    # We'll temporarily skip this enhancement for geo, since in some situations we
    # wish to setup the geo database before the other databases have been setup,
    # and partition management attempts to connect to the main database.
    each_database(databases) do |database_name|
      # :nocov:
      Rake::Task["db:schema:load:#{database_name}"].enhance do
        Rake::Task["gitlab:db:create_dynamic_partitions:#{database_name}"].invoke
      end
      # :nocov:
    end

    # During testing, db:test:load_schema restores the database schema from scratch
    # which does not include dynamic partitions. We cannot rely on application
    # initializers here as the application can continue to run while
    # a rake task reloads the database schema.
    Rake::Task['db:test:load_schema'].enhance do
      # Due to bug in `db:test:load_schema` if many DBs are used
      # the `ActiveRecord::Base.connection` might be switched to another one
      # This is due to `if should_reconnect`:
      # https://github.com/rails/rails/blob/a81aeb63a007ede2fe606c50539417dada9030c7/activerecord/lib/active_record/railties/databases.rake#L622
      ActiveRecord::Base.establish_connection :main # rubocop: disable Database/EstablishConnection

      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    desc "Reindex database without downtime to eliminate bloat"
    task reindex: :environment do
      unless Gitlab::Database::Reindexing.enabled?
        puts Rainbow("This feature (database_reindexing) is currently disabled.").yellow
        exit
      end

      Gitlab::Database::Reindexing.invoke
    end

    namespace :reindex do
      each_database(databases) do |database_name|
        desc "Reindex #{database_name} database without downtime to eliminate bloat"
        task database_name => :environment do
          unless Gitlab::Database::Reindexing.enabled?
            puts Rainbow("This feature (database_reindexing) is currently disabled.").yellow
            exit
          end

          Gitlab::Database::Reindexing.invoke(database_name)
        end
      end
    end

    def disabled_db_flags_note
      return unless Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops)

      puts Rainbow(<<~NOTE).yellow
          Note: disallow_database_ddl_feature_flags feature is currently enabled. Disable it to proceed.

          Disable with: Feature.disable(:disallow_database_ddl_feature_flags)
      NOTE

      yield if block_given?
    end

    desc 'Enqueue an index for reindexing'
    task :enqueue_reindexing_action, [:index_name, :database] => :environment do |_, args|
      model = Gitlab::Database.database_base_models[args.fetch(:database, Gitlab::Database::PRIMARY_DATABASE_NAME)]

      Gitlab::Database::SharedModel.using_connection(model.connection) do
        queued_action = Gitlab::Database::PostgresIndex.find(args[:index_name]).queued_reindexing_actions.create!

        puts "Queued reindexing action: #{queued_action}"
        puts "There are #{Gitlab::Database::Reindexing::QueuedAction.queued.size} queued actions in total."
      end

      disabled_db_flags_note

      if Feature.disabled?(:database_reindexing, type: :ops)
        puts Rainbow(<<~NOTE).yellow
          Note: database_reindexing feature is currently disabled.

          Enable with: Feature.enable(:database_reindexing)
        NOTE
      end
    end

    namespace :execute_async_index_operations do
      each_database(databases) do |database_name|
        task database_name, [:pick] => :environment do |_, args|
          args.with_defaults(pick: 2)

          disabled_db_flags_note { exit }

          if Feature.disabled?(:database_async_index_operations, type: :ops)
            puts Rainbow(<<~NOTE).yellow
              Note: database async index operations feature is currently disabled.

              Enable with: Feature.enable(:database_async_index_operations)
            NOTE
            exit
          end

          Gitlab::Database::EachDatabase.each_connection(only: database_name) do
            Gitlab::Database::AsyncIndexes.execute_pending_actions!(how_many: args[:pick].to_i)
          end
        end
      end

      task :all, [:pick] => :environment do |_, args|
        default_pick = Gitlab.dev_or_test_env? ? 1000 : 2
        args.with_defaults(pick: default_pick)

        each_database(databases) do |database_name|
          Rake::Task["gitlab:db:execute_async_index_operations:#{database_name}"].invoke(args[:pick])
        end
      end
    end

    namespace :validate_async_constraints do
      each_database(databases) do |database_name|
        task database_name, [:pick] => :environment do |_, args|
          args.with_defaults(pick: 2)

          disabled_db_flags_note { exit }

          if Feature.disabled?(:database_async_foreign_key_validation, type: :ops)
            puts Rainbow(<<~NOTE).yellow
              Note: database async foreign key validation feature is currently disabled.

              Enable with: Feature.enable(:database_async_foreign_key_validation)
            NOTE
            exit
          end

          Gitlab::Database::EachDatabase.each_connection(only: database_name) do
            Gitlab::Database::AsyncConstraints.validate_pending_entries!(how_many: args[:pick].to_i)
          end
        end
      end

      task :all, [:pick] => :environment do |_, args|
        default_pick = Gitlab.dev_or_test_env? ? 1000 : 2
        args.with_defaults(pick: default_pick)

        each_database(databases) do |database_name|
          Rake::Task["gitlab:db:validate_async_constraints:#{database_name}"].invoke(args[:pick])
        end
      end
    end

    desc 'Check if there have been user additions to the database'
    task active: :environment do
      if ActiveRecord::Base.connection.migration_context.needs_migration?
        puts "Migrations pending. Database not active"
        exit 1
      end

      if Project.count.eql?(0)
        puts "No user created projects. Database not active"
        exit 1
      end

      puts "Found user created projects. Database active"
      exit 0
    end

    namespace :migration_testing do
      # Not possible to import Gitlab::Database::DATABASE_NAMES here
      # Specs verify that a task exists for each entry in that array.
      all_databases = %i[main ci sec]

      task up: :environment do
        Gitlab::Database::Migrations::Runner.up(database: 'main', legacy_mode: true).run
      end

      namespace :up do
        all_databases.each do |db|
          desc "Run migrations on #{db} with instrumentation"
          task db => :environment do
            next unless Gitlab::Database.has_database?(db)

            Gitlab::Database::Migrations::Runner.batched_migrations_last_id(db).store
            Gitlab::Database::Migrations::Runner.up(database: db).run
          end
        end
      end

      namespace :down do
        all_databases.each do |db|
          desc "Run down migrations on #{db} in current branch with instrumentation"
          task db => :environment do
            next unless Gitlab::Database.has_database?(db)

            Gitlab::Database::Migrations::Runner.down(database: db).run
          end
        end
      end

      desc 'Sample traditional background migrations with instrumentation'
      task :sample_background_migrations, [:duration_s] => [:environment] do |_t, args|
        duration = args[:duration_s]&.to_i&.seconds || 30.minutes # Default of 30 minutes

        Gitlab::Database::Migrations::Runner.background_migrations.run_jobs(for_duration: duration)
      end

      namespace :sample_batched_background_migrations do
        all_databases.each do |db|
          desc "Sample batched background migrations on #{db} with instrumentation"
          task db, [:duration_s] => [:environment] do |_t, args|
            next unless Gitlab::Database.has_database?(db)

            duration = args[:duration_s]&.to_i&.seconds || 30.minutes # Default of 30 minutes

            Gitlab::Database::Migrations::Runner.batched_background_migrations(for_database: db)
                                                .run_jobs(for_duration: duration)
          end
        end
      end

      desc "Sample batched background migrations with instrumentation (legacy)"
      task :sample_batched_background_migrations, [:database, :duration_s] => [:environment] do |_t, args|
        duration = args[:duration_s]&.to_i&.seconds || 30.minutes # Default of 30 minutes

        database = args[:database] || 'main'
        Gitlab::Database::Migrations::Runner.batched_background_migrations(for_database: database, legacy_mode: true)
                                            .run_jobs(for_duration: duration)
      end
    end

    desc 'Run all pending batched migrations'
    task execute_batched_migrations: :environment do
      Gitlab::Database::EachDatabase.each_connection do |connection, name|
        Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:active).queue_order.each do |migration|
          Gitlab::AppLogger.info("Executing batched migration #{migration.id} on database #{name} inline")
          Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new(connection: connection).run_entire_migration(migration)
        end
      end
    end

    desc 'Run migration as gitlab non-superuser'
    task :reset_as_non_superuser, [:username] => :environment do |_, args|
      username = args.fetch(:username, 'gitlab')
      puts "Migrate using username #{username}"
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each do |db_config|
        config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
          db_config.env_name,
          db_config.name,
          db_config.configuration_hash.merge(username: username)
        )

        ActiveRecord::Base.establish_connection(config) # rubocop: disable Database/EstablishConnection
        Gitlab::Database.check_for_non_superuser

        if Rake::Task.task_defined?("db:migrate:#{db_config.name}")
          Rake::Task["db:migrate:#{db_config.name}"].invoke
        else
          Rake::Task["db:migrate"].invoke
        end
      end
    end

    # Only for development environments,
    # we execute pending data migrations inline for convenience.
    Rake::Task['db:migrate'].enhance do
      if Rails.env.development? && Gitlab::Database::BackgroundMigration::BatchedMigration.table_exists?
        Rake::Task['gitlab:db:execute_batched_migrations'].invoke
      end
    end

    namespace :schema_checker do
      # TODO: Remove `test_replication` after PG 14 upgrade is finished
      # https://gitlab.com/gitlab-com/gl-infra/db-migration/-/merge_requests/406#note_1369214728
      IGNORED_TABLES = %w[test_replication].freeze
      IGNORED_TRIGGERS = ['gitlab_schema_write_trigger_for_'].freeze

      desc 'Checks schema inconsistencies'
      task run: :environment do
        logger = Logger.new($stdout)

        database_model = Gitlab::Database.database_base_models[Gitlab::Database::MAIN_DATABASE_NAME]
        database = Gitlab::Schema::Validation::Sources::Database.new(database_model.connection)

        stucture_sql_path = Rails.root.join('db/structure.sql')
        structure_sql = Gitlab::Schema::Validation::Sources::StructureSql.new(stucture_sql_path)

        filter = Gitlab::Database::SchemaValidation::InconsistencyFilter.new(IGNORED_TABLES, IGNORED_TRIGGERS)

        validators = Gitlab::Schema::Validation::Validators::Base.all_validators

        inconsistencies =
          Gitlab::Schema::Validation::Runner.new(structure_sql, database, validators: validators).execute.filter_map(&filter)

        inconsistencies.each do |inconsistency|
          puts inconsistency.display
        end
        logger.info "This task is a diagnostic tool to be used under the guidance of GitLab Support. You should not use the task for routine checks as database inconsistencies might be expected."
      end
    end

    namespace :dictionary do
      desc 'Generate database docs yaml'
      task generate: :environment do
        next if Gitlab.jh?

        Gitlab::Database.all_database_connections.values.map(&:db_docs_dir).each do |db_dir|
          FileUtils.mkdir_p(db_dir)
        end

        Rails.application.eager_load!

        version = Gem::Version.new(File.read('VERSION'))
        milestone = version.release.segments.first(2).join('.')

        classes = {}

        Gitlab::Database.database_base_models.each do |_, model_class|
          tables = model_class.connection.tables

          views = model_class.connection.views

          sources = tables + views

          model_classes = sources.index_with { [] }

          classes.merge!(model_classes) { |_, sources, new_sources| sources + new_sources }

          model_class
            .descendants
            .reject(&:abstract_class)
            .reject { |c| c.name =~ /^(?:EE::)?Gitlab::(?:BackgroundMigration|DatabaseImporters)::/ }
            .reject { |c| c.name =~ /^HABTM_/ }
            .reject { |c| c < Gitlab::Database::Migration[1.0]::MigrationRecord }
            .reject { |c| c.name == 'TmpUser' }
            .each { |c| classes[c.table_name] << c.name if classes.has_key?(c.table_name) && c.name.present? }

          sources.each do |source_name|
            next if source_name.start_with?('_test_') # Ignore test tables

            database = model_class.connection_db_config.name
            file = dictionary_file_path(source_name, views, database)
            key_name = "#{data_source_type(source_name, views)}_name"

            table_metadata = {
              key_name => source_name,
              'classes' => classes[source_name]&.sort&.uniq,
              'feature_categories' => [],
              'description' => nil,
              'introduced_by_url' => nil,
              'milestone' => milestone,
              'table_size' => 'small'
            }

            if File.exist?(file)
              outdated = false

              existing_metadata = YAML.safe_load(File.read(file))

              if existing_metadata[key_name] != table_metadata[key_name]
                existing_metadata[key_name] = table_metadata[key_name]
                outdated = true
              end

              if existing_metadata['classes'] && existing_metadata['classes'].sort != table_metadata['classes'].sort
                existing_metadata['classes'] = (existing_metadata['classes'] + table_metadata['classes']).uniq.sort
                outdated = true
              end

              File.write(file, existing_metadata.to_yaml) if outdated
            else
              File.write(file, table_metadata.to_yaml)
            end
          end
        end
      end

      private

      def data_source_type(source_name, views)
        return 'view' if views.include?(source_name)

        'table'
      end

      def dictionary_file_path(source_name, views, database)
        sub_directory = views.include?(source_name) ? 'views' : ''

        path = Gitlab::Database.all_database_connections.fetch(database).db_docs_dir
        File.join(path, sub_directory, "#{source_name}.yml")
      end

      Rake::Task['db:migrate'].enhance do
        Rake::Task['gitlab:db:dictionary:generate'].invoke if Rails.env.development?
      end
    end
  end
end

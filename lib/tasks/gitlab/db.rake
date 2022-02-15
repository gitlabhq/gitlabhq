# frozen_string_literal: true

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

namespace :gitlab do
  namespace :db do
    desc 'GitLab | DB | Manually insert schema migration version'
    task :mark_migration_complete, [:version] => :environment do |_, args|
      mark_migration_complete(args[:version])
    end

    namespace :mark_migration_complete do
      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
        desc "Gitlab | DB | Manually insert schema migration version on #{name} database"
        task name, [:version] => :environment do |_, args|
          mark_migration_complete(args[:version], database: name)
        end
      end
    end

    def mark_migration_complete(version, database: nil)
      if version.to_i == 0
        puts 'Must give a version argument that is a non-zero integer'.color(:red)
        exit 1
      end

      Gitlab::Database.database_base_models.each do |name, model|
        next if database && database.to_s != name

        model.connection.execute("INSERT INTO schema_migrations (version) VALUES (#{model.connection.quote(version)})")

        puts "Successfully marked '#{version}' as complete on database #{name}".color(:green)
      rescue ActiveRecord::RecordNotUnique
        puts "Migration version '#{version}' is already marked complete on database #{name}".color(:yellow)
      end
    end

    desc 'GitLab | DB | Drop all tables'
    task drop_tables: :environment do
      connection = ActiveRecord::Base.connection

      # In PostgreSQLAdapter, data_sources returns both views and tables, so use
      # #tables instead
      tables = connection.tables

      # Removes the entry from the array
      tables.delete 'schema_migrations'
      # Truncate schema_migrations to ensure migrations re-run
      connection.execute('TRUNCATE schema_migrations') if connection.table_exists? 'schema_migrations'

      # Drop any views
      connection.views.each do |view|
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

    desc 'GitLab | DB | Configures the database by running migrate, or by loading the schema and seeding if needed'
    task configure: :environment do
      # Check if we have existing db tables
      # The schema_migrations table will still exist if drop_tables was called
      if ActiveRecord::Base.connection.tables.count > 1
        Rake::Task['db:migrate'].invoke
      else
        # Add post-migrate paths to ensure we mark all migrations as up
        Gitlab::Database.add_post_migrate_path_to_rails(force: true)
        Rake::Task['db:structure:load'].invoke
        Rake::Task['db:seed_fu'].invoke
      end
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

    desc 'GitLab | DB | Sets up EE specific database functionality'

    if Gitlab.ee?
      task setup_ee: %w[db:drop:geo db:create:geo db:schema:load:geo db:migrate:geo]
    else
      task :setup_ee
    end

    desc 'This adjusts and cleans db/structure.sql - it runs after db:structure:dump'
    task :clean_structure_sql do |task_name|
      ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each do |db_config|
        structure_file = ActiveRecord::Tasks::DatabaseTasks.dump_filename(db_config.name)

        schema = File.read(structure_file)

        File.open(structure_file, 'wb+') do |io|
          Gitlab::Database::SchemaCleaner.new(schema).clean(io)
        end
      end

      # Allow this task to be called multiple times, as happens when running db:migrate:redo
      Rake::Task[task_name].reenable
    end

    # Inform Rake that custom tasks should be run every time rake db:structure:dump is run
    #
    # Rails 6.1 deprecates db:structure:dump in favor of db:schema:dump
    Rake::Task['db:structure:dump'].enhance do
      Rake::Task['gitlab:db:clean_structure_sql'].invoke
    end

    # Inform Rake that custom tasks should be run every time rake db:schema:dump is run
    Rake::Task['db:schema:dump'].enhance do
      Rake::Task['gitlab:db:clean_structure_sql'].invoke
    end

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      # Inform Rake that custom tasks should be run every time rake db:structure:dump is run
      #
      # Rails 6.1 deprecates db:structure:dump in favor of db:schema:dump
      Rake::Task["db:structure:dump:#{name}"].enhance do
        Rake::Task['gitlab:db:clean_structure_sql'].invoke
      end

      Rake::Task["db:schema:dump:#{name}"].enhance do
        Rake::Task['gitlab:db:clean_structure_sql'].invoke
      end
    end

    desc 'Create missing dynamic database partitions'
    task create_dynamic_partitions: :environment do
      Gitlab::Database::Partitioning.sync_partitions
    end

    # This is targeted towards deploys and upgrades of GitLab.
    # Since we're running migrations already at this time,
    # we also check and create partitions as needed here.
    Rake::Task['db:migrate'].enhance do
      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    # When we load the database schema from db/structure.sql
    # we don't have any dynamic partitions created. We don't really need to
    # because application initializers/sidekiq take care of that, too.
    # However, the presence of partitions for a table has influence on their
    # position in db/structure.sql (which is topologically sorted).
    #
    # Other than that it's helpful to create partitions early when bootstrapping
    # a new installation.
    #
    # Rails 6.1 deprecates db:structure:load in favor of db:schema:load
    Rake::Task['db:structure:load'].enhance do
      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    Rake::Task['db:schema:load'].enhance do
      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    # During testing, db:test:load restores the database schema from scratch
    # which does not include dynamic partitions. We cannot rely on application
    # initializers here as the application can continue to run while
    # a rake task reloads the database schema.
    Rake::Task['db:test:load'].enhance do
      # Due to bug in `db:test:load` if many DBs are used
      # the `ActiveRecord::Base.connection` might be switched to another one
      # This is due to `if should_reconnect`:
      # https://github.com/rails/rails/blob/a81aeb63a007ede2fe606c50539417dada9030c7/activerecord/lib/active_record/railties/databases.rake#L622
      ActiveRecord::Base.establish_connection :main # rubocop: disable Database/EstablishConnection

      Rake::Task['gitlab:db:create_dynamic_partitions'].invoke
    end

    desc "Reindex database without downtime to eliminate bloat"
    task reindex: :environment do
      unless Gitlab::Database::Reindexing.enabled?
        puts "This feature (database_reindexing) is currently disabled.".color(:yellow)
        exit
      end

      Gitlab::Database::Reindexing.invoke
    end

    namespace :reindex do
      databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

      ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database_name|
        desc "Reindex #{database_name} database without downtime to eliminate bloat"
        task database_name => :environment do
          unless Gitlab::Database::Reindexing.enabled?
            puts "This feature (database_reindexing) is currently disabled.".color(:yellow)
            exit
          end

          Gitlab::Database::Reindexing.invoke(database_name)
        end
      end
    end

    desc 'Enqueue an index for reindexing'
    task :enqueue_reindexing_action, [:index_name, :database] => :environment do |_, args|
      model = Gitlab::Database.database_base_models[args.fetch(:database, Gitlab::Database::PRIMARY_DATABASE_NAME)]

      Gitlab::Database::SharedModel.using_connection(model.connection) do
        queued_action = Gitlab::Database::PostgresIndex.find(args[:index_name]).queued_reindexing_actions.create!

        puts "Queued reindexing action: #{queued_action}"
        puts "There are #{Gitlab::Database::Reindexing::QueuedAction.queued.size} queued actions in total."
      end

      unless Feature.enabled?(:database_reindexing, type: :ops, default_enabled: :yaml)
        puts <<~NOTE.color(:yellow)
          Note: database_reindexing feature is currently disabled.

          Enable with: Feature.enable(:database_reindexing)
        NOTE
      end
    end

    desc 'Check if there have been user additions to the database'
    task active: :environment do
      if ActiveRecord::Base.connection.migration_context.needs_migration?
        puts "Migrations pending. Database not active"
        exit 1
      end

      # A list of projects that GitLab creates automatically on install/upgrade
      # gc = Gitlab::CurrentSettings.current_application_settings
      seed_projects = [Gitlab::CurrentSettings.current_application_settings.self_monitoring_project]

      if (Project.count - seed_projects.count {|x| !x.nil? }).eql?(0)
        puts "No user created projects. Database not active"
        exit 1
      end

      puts "Found user created projects. Database active"
      exit 0
    end

    namespace :migration_testing do
      desc 'Run migrations with instrumentation'
      task up: :environment do
        Gitlab::Database::Migrations::Runner.up.run
      end

      desc 'Run down migrations in current branch with instrumentation'
      task down: :environment do
        Gitlab::Database::Migrations::Runner.down.run
      end
    end

    desc 'Run all pending batched migrations'
    task execute_batched_migrations: :environment do
      Gitlab::Database::BackgroundMigration::BatchedMigration.active.queue_order.each do |migration|
        Gitlab::AppLogger.info("Executing batched migration #{migration.id} inline")
        Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new.run_entire_migration(migration)
      end
    end

    # Only for development environments,
    # we execute pending data migrations inline for convenience.
    Rake::Task['db:migrate'].enhance do
      if Rails.env.development? && Gitlab::Database::BackgroundMigration::BatchedMigration.table_exists?
        Rake::Task['gitlab:db:execute_batched_migrations'].invoke
      end
    end
  end
end

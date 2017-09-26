task spec: ['geo:db:test:prepare']

namespace :geo do
  namespace :db do |ns|
    include ActiveRecord::Tasks

    desc 'Drops the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task :drop do
      with_geo_db do
        DatabaseTasks.drop_current
      end
    end

    desc 'Creates the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task :create do
      with_geo_db do
        DatabaseTasks.create_current
      end
    end

    desc 'Create the Geo tracking database, load the schema, and initialize with the seed data.'
    task setup: ['geo:db:schema:load', 'geo:db:seed']

    desc 'Migrate the Geo tracking database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
    task migrate: [:environment] do
      with_geo_db do
        DatabaseTasks.migrate
      end
      ns['_dump'].invoke
    end

    desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task rollback: [:environment] do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1

      with_geo_db do
        ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
      end
      ns['_dump'].invoke
    end

    desc 'Retrieves the current schema version number.'
    task version: [:environment] do
      with_geo_db do
        puts "Current version: #{ActiveRecord::Migrator.current_version}"
      end
    end

    desc 'Drops and recreates the database from db/geo/schema.rb for the current environment and loads the seeds.'
    task reset: [:environment] do
      ns['drop'].invoke
      ns['create'].invoke
      ns['setup'].invoke
    end

    desc 'Load the seed data from db/seeds.rb'
    task seed: [:environment] do
      ns['abort_if_pending_migrations'].invoke

      with_geo_db do
        DatabaseTasks.load_seed # Without setting DatabaseTasks.seed_loader it will load from db/seeds.rb
      end
    end

    desc 'Display database encryption key'
    task show_encryption_key: :environment do
      puts Rails.application.secrets.db_key_base
    end

    # IMPORTANT: This task won't dump the schema if ActiveRecord::Base.dump_schema_after_migration is set to false
    task :_dump do
      with_geo_db do # TODO should this be in `with_geo_db` ?
        if ActiveRecord::Base.dump_schema_after_migration
          ns["schema:dump"].invoke
        end
      end
      # Allow this task to be called as many times as required. An example is the
      # migrate:redo task, which calls other two internally that depend on this one.
      ns['_dump'].reenable
    end

    # desc "Raises an error if there are pending migrations"
    task abort_if_pending_migrations: [:environment] do
      with_geo_db do
        pending_migrations = ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations

        if pending_migrations.any?
          puts "You have #{pending_migrations.size} pending #{pending_migrations.size > 1 ? 'migrations:' : 'migration:'}"
          pending_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          abort %{Run `rake geo:db:migrate` to update your database then try again.}
        end
      end
    end

    namespace :schema do
      desc 'Load a schema.rb file into the database'
      task load: [:environment] do
        with_geo_db do
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, ENV['SCHEMA'])
        end
      end

      desc 'Create a db/geo/schema.rb file that is portable against any DB supported by AR'
      task dump: [:environment] do
        require 'active_record/schema_dumper'

        with_geo_db do
          filename = ENV['SCHEMA'] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
          File.open(filename, "w:utf-8") do |file|
            ActiveRecord::SchemaDumper.dump(Geo::BaseRegistry.connection, file)
          end
        end

        ns['schema:dump'].reenable
      end
    end

    namespace :migrate do
      desc 'Runs the "up" for a given migration VERSION.'
      task up: [:environment] do
        version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
        raise 'VERSION is required' unless version

        with_geo_db do
          ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, version)
        end
        ns['_dump'].invoke
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task down: [:environment] do
        version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
        raise 'VERSION is required - To go down one migration, run db:rollback' unless version

        with_geo_db do
          ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)
        end
        ns['_dump'].invoke
      end

      desc 'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
      task redo: [:environment] do
        if ENV['VERSION']
          ns['migrate:down'].invoke
          ns['migrate:up'].invoke
        else
          ns['rollback'].invoke
          ns['migrate'].invoke
        end
      end

      desc 'Display status of migrations' # TODO test
      task status: [:environment] do
        with_geo_db do
          unless ActiveRecord::SchemaMigration.table_exists?
            abort 'Schema migrations table does not exist yet.'
          end
          db_list = ActiveRecord::SchemaMigration.normalized_versions

          file_list =
            ActiveRecord::Migrator.migrations_paths.flat_map do |path|
            # match "20091231235959_some_name.rb" and "001_some_name.rb" pattern
            Dir.foreach(path).grep(/^(\d{3,})_(.+)\.rb$/) do
              version = ActiveRecord::SchemaMigration.normalize_migration_number($1)
              status = db_list.delete(version) ? 'up' : 'down'
              [status, version, $2.humanize]
            end
          end

          db_list.map! do |version|
            ['up', version, '********** NO FILE **********']
          end
          # output
          puts "\ndatabase: #{ActiveRecord::Base.connection_config[:database]}\n\n"
          puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
          puts "-" * 50
          (db_list + file_list).sort_by { |_, version, _| version }.each do |status, version, name|
            puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
          end
          puts
        end
      end
    end

    namespace :test do
      desc 'Check for pending migrations and load the test schema'
      task prepare: [:environment] do
        with_geo_db do
          unless ActiveRecord::Base.configurations.blank?
            ns['test:load'].invoke
          end
        end
      end

      # desc "Recreate the test database from the current schema"
      task load: [:environment, 'geo:db:test:purge'] do
        with_geo_db do
          begin
            should_reconnect = ActiveRecord::Base.connection_pool.active_connection?
            ActiveRecord::Schema.verbose = false
            ActiveRecord::Tasks::DatabaseTasks.load_schema_for ActiveRecord::Base.configurations['test'], :ruby, ENV['SCHEMA']
          ensure
            if should_reconnect
              ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ActiveRecord::Tasks::DatabaseTasks.env])
            end
          end
        end
      end

      # desc "Empty the test database"
      task purge: [:environment] do
        with_geo_db do
          ActiveRecord::Tasks::DatabaseTasks.purge ActiveRecord::Base.configurations['test']
        end
      end
    end
  end

  desc 'Make this node the Geo primary'
  task set_primary_node: :environment do
    abort 'GitLab Geo is not supported with this license. Please contact sales@gitlab.com.' unless Gitlab::Geo.license_allows?
    abort 'GitLab Geo primary node already present' if Gitlab::Geo.primary_node.present?

    set_primary_geo_node
  end

  def set_primary_geo_node
    params = {
      schema: Gitlab.config.gitlab.protocol,
      host: Gitlab.config.gitlab.host,
      port: Gitlab.config.gitlab.port,
      relative_url_root: Gitlab.config.gitlab.relative_url_root,
      primary: true
    }

    node = GeoNode.new(params)
    puts "Saving primary GeoNode with URL #{node.url}".color(:green)
    node.save

    puts "Error saving GeoNode:\n#{node.errors.full_messages.join("\n")}".color(:red) unless node.persisted?
  end

  GEO_DATABASE_CONFIG = 'config/database_geo.yml'.freeze

  def geo_settings
    db_dir = 'db/geo'
    {
      database_config: YAML.load_file(GEO_DATABASE_CONFIG),
      db_dir: db_dir,
      migrations_paths: [Rails.root.join(db_dir, 'migrate')]
    }
  end

  def abort_if_no_geo_config!
    @geo_config_exists ||= File.exist?(Rails.root.join(GEO_DATABASE_CONFIG))

    unless @geo_config_exists
      abort("Failed to open #{GEO_DATABASE_CONFIG}. Consult the documentation on how to set up GitLab Geo.")
    end
  end

  def with_geo_db
    abort_if_no_geo_config!

    original_settings = {
      database_config: DatabaseTasks.database_configuration&.dup || YAML.load_file('config/database.yml'),
      db_dir: DatabaseTasks.db_dir,
      migrations_paths: DatabaseTasks.migrations_paths
    }

    set_db_env(geo_settings)

    yield

    set_db_env(original_settings)
  end

  def set_db_env(settings)
    DatabaseTasks.database_configuration = settings[:database_config]
    DatabaseTasks.db_dir = settings[:db_dir]
    DatabaseTasks.migrations_paths = settings[:migrations_paths]

    ActiveRecord::Base.configurations       = DatabaseTasks.database_configuration || {}
    ActiveRecord::Migrator.migrations_paths = DatabaseTasks.migrations_paths

    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ActiveRecord::Tasks::DatabaseTasks.env])
  end
end

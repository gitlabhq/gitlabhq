require 'gitlab/geo'
require 'gitlab/geo/database_tasks'

task spec: ['geo:db:test:prepare']

namespace :geo do
  namespace :db do |ns|
    desc 'Drops the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task :drop do
      Gitlab::Geo::DatabaseTasks.drop_current
    end

    desc 'Creates the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task :create do
      Gitlab::Geo::DatabaseTasks.create_current
    end

    desc 'Create the Geo tracking database, load the schema, and initialize with the seed data.'
    task setup: ['geo:db:schema:load', 'geo:db:seed']

    desc 'Migrate the Geo tracking database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
    task migrate: [:environment] do
      Gitlab::Geo::DatabaseTasks.migrate

      ns['_dump'].invoke
    end

    desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task rollback: [:environment] do
      Gitlab::Geo::DatabaseTasks.rollback

      ns['_dump'].invoke
    end

    desc 'Retrieves the current schema version number.'
    task version: [:environment] do
      puts "Current version: #{Gitlab::Geo::DatabaseTasks.version}"
    end

    desc 'Drops and recreates the database from db/geo/schema.rb for the current environment and loads the seeds.'
    task reset: [:environment] do
      ns['drop'].invoke
      ns['create'].invoke
      ns['setup'].invoke
    end

    desc 'Load the seed data from db/geo/seeds.rb'
    task seed: [:environment] do
      ns['abort_if_pending_migrations'].invoke

      Gitlab::Geo::DatabaseTasks.load_seed
    end

    desc 'Display database encryption key'
    task show_encryption_key: :environment do
      puts Rails.application.secrets.db_key_base
    end

    # IMPORTANT: This task won't dump the schema if ActiveRecord::Base.dump_schema_after_migration is set to false
    task :_dump do
      if Gitlab::Geo::DatabaseTasks.dump_schema_after_migration?
        ns["schema:dump"].invoke
      end
      # Allow this task to be called as many times as required. An example is the
      # migrate:redo task, which calls other two internally that depend on this one.
      ns['_dump'].reenable
    end

    # desc "Raises an error if there are pending migrations"
    task abort_if_pending_migrations: [:environment] do
      pending_migrations = Gitlab::Geo::DatabaseTasks.pending_migrations

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending #{pending_migrations.size > 1 ? 'migrations:' : 'migration:'}"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run `rake geo:db:migrate` to update your database then try again.}
      end
    end

    namespace :schema do
      desc 'Load a schema.rb file into the database'
      task load: [:environment] do
        Gitlab::Geo::DatabaseTasks.load_schema_current(:ruby, ENV['SCHEMA'])
      end

      desc 'Create a db/geo/schema.rb file that is portable against any DB supported by AR'
      task dump: [:environment] do
        Gitlab::Geo::DatabaseTasks::Schema.dump

        ns['schema:dump'].reenable
      end
    end

    namespace :migrate do
      desc 'Runs the "up" for a given migration VERSION.'
      task up: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.up

        ns['_dump'].invoke
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task down: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.down

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

      desc 'Display status of migrations'
      task status: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.status
      end
    end

    namespace :test do
      desc 'Check for pending migrations and load the test schema'
      task prepare: [:environment] do
        ns['test:load'].invoke
      end

      # desc "Recreate the test database from the current schema"
      task load: [:environment, 'geo:db:test:purge'] do
        Gitlab::Geo::DatabaseTasks::Test.load
      end

      # desc "Empty the test database"
      task purge: [:environment] do
        Gitlab::Geo::DatabaseTasks::Test.purge
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
end

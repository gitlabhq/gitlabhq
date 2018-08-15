require 'action_view/helpers'

task spec: ['geo:db:test:prepare']

namespace :geo do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  GEO_LICENSE_ERROR_TEXT = 'GitLab Geo is not supported with this license. Please contact sales@gitlab.com.'.freeze

  namespace :db do |ns|
    desc 'Drops the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task drop: [:environment] do
      Gitlab::Geo::DatabaseTasks.drop_current
    end

    desc 'Creates the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task create: [:environment] do
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

    desc 'Drops and recreates the database from ee/db/geo/schema.rb for the current environment and loads the seeds.'
    task reset: [:environment] do
      ns['drop'].invoke
      ns['create'].invoke
      ns['setup'].invoke
    end

    desc 'Load the seed data from ee/db/geo/seeds.rb'
    task seed: [:environment] do
      ns['abort_if_pending_migrations'].invoke

      Gitlab::Geo::DatabaseTasks.load_seed
    end

    desc 'Refresh Foreign Tables definition in Geo Secondary node'
    task refresh_foreign_tables: [:environment] do
      if Gitlab::Geo::GeoTasks.foreign_server_configured?
        print "\nRefreshing foreign tables for FDW: #{Gitlab::Geo::Fdw::FDW_SCHEMA} ... "
        Gitlab::Geo::GeoTasks.refresh_foreign_tables!
        puts 'Done!'
      else
        puts "Error: Cannot refresh foreign tables, there is no foreign server configured."
        exit 1
      end
    end

    # IMPORTANT: This task won't dump the schema if ActiveRecord::Base.dump_schema_after_migration is set to false
    task _dump: [:environment] do
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

      desc 'Create a ee/db/geo/schema.rb file that is portable against any DB supported by AR'
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

      desc 'Refresh Foreign Tables definition for test environment'
      task refresh_foreign_tables: [:environment] do
        old_env = ActiveRecord::Tasks::DatabaseTasks.env
        ActiveRecord::Tasks::DatabaseTasks.env = 'test'

        ns['geo:db:refresh_foreign_tables'].invoke

        ActiveRecord::Tasks::DatabaseTasks.env = old_env
      end
    end
  end

  desc 'Make this node the Geo primary'
  task set_primary_node: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?
    abort 'GitLab Geo primary node already present' if Gitlab::Geo.primary_node.present?

    Gitlab::Geo::GeoTasks.set_primary_geo_node
  end

  desc 'Make this secondary node the primary'
  task set_secondary_as_primary: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    ActiveRecord::Base.transaction do
      primary_node = Gitlab::Geo.primary_node

      unless primary_node
        abort 'The primary is not set'
      end

      primary_node.destroy

      current_node = Gitlab::Geo.current_node

      unless current_node.secondary?
        abort 'This is not a secondary node'
      end

      current_node.update!(primary: true)
    end
  end

  desc 'Update Geo primary node URL'
  task update_primary_node_url: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    Gitlab::Geo::GeoTasks.update_primary_geo_node_url
  end

  desc 'Print Geo node status'
  task status: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    COLUMN_WIDTH = 40
    current_node_status = GeoNodeStatus.current_node_status
    geo_node = current_node_status.geo_node

    unless geo_node.secondary?
      puts 'This command is only available on a secondary node'.color(:red)
      exit
    end

    puts
    puts GeoNode.current_node_url
    puts '-----------------------------------------------------'.color(:yellow)

    unless Gitlab::Database.pg_stat_wal_receiver_supported?
      puts
      puts 'WARNING: Please upgrade PostgreSQL to version 9.6 or greater. The status of the replication cannot be determined reliably with the current version.'.color(:red)
      puts
    end

    print 'GitLab Version: '.rjust(COLUMN_WIDTH)
    puts Gitlab::VERSION

    print 'Geo Role: '.rjust(COLUMN_WIDTH)
    role =
      if Gitlab::Geo.primary?
        'Primary'
      else
        Gitlab::Geo.secondary? ? 'Secondary' : 'unknown'.color(:yellow)
      end

    puts role

    print 'Health Status: '.rjust(COLUMN_WIDTH)

    if current_node_status.healthy?
      puts current_node_status.health_status
    else
      puts current_node_status.health_status.color(:red)
    end

    print 'Repositories: '.rjust(COLUMN_WIDTH)
    show_failed_value(current_node_status.repositories_failed_count)
    print "#{current_node_status.repositories_synced_count}/#{current_node_status.projects_count} "
    puts using_percentage(current_node_status.repositories_synced_in_percentage)

    if Gitlab::Geo.repository_verification_enabled?
      print 'Verified Repositories: '.rjust(COLUMN_WIDTH)
      show_failed_value(current_node_status.repositories_verification_failed_count)
      print "#{current_node_status.repositories_verified_count}/#{current_node_status.projects_count} "
      puts using_percentage(current_node_status.repositories_verified_in_percentage)
    end

    print 'Wikis: '.rjust(COLUMN_WIDTH)
    show_failed_value(current_node_status.wikis_failed_count)
    print "#{current_node_status.wikis_synced_count}/#{current_node_status.wikis_count} "
    puts using_percentage(current_node_status.wikis_synced_in_percentage)

    if Gitlab::Geo.repository_verification_enabled?
      print 'Verified Wikis: '.rjust(COLUMN_WIDTH)
      show_failed_value(current_node_status.wikis_verification_failed_count)
      print "#{current_node_status.wikis_verified_count}/#{current_node_status.wikis_count} "
      puts using_percentage(current_node_status.wikis_verified_in_percentage)
    end

    print 'LFS Objects: '.rjust(COLUMN_WIDTH)
    show_failed_value(current_node_status.lfs_objects_failed_count)
    print "#{current_node_status.lfs_objects_synced_count}/#{current_node_status.lfs_objects_count} "
    puts using_percentage(current_node_status.lfs_objects_synced_in_percentage)

    print 'Attachments: '.rjust(COLUMN_WIDTH)
    show_failed_value(current_node_status.attachments_failed_count)
    print "#{current_node_status.attachments_synced_count}/#{current_node_status.attachments_count} "
    puts using_percentage(current_node_status.attachments_synced_in_percentage)

    if Gitlab::CurrentSettings.repository_checks_enabled
      print 'Repositories Checked: '.rjust(COLUMN_WIDTH)
      show_failed_value(current_node_status.repositories_checked_failed_count)
      print "#{current_node_status.repositories_checked_count}/#{current_node_status.projects_count} "
      puts using_percentage(current_node_status.repositories_checked_in_percentage)
    end

    print 'Sync Settings: '.rjust(COLUMN_WIDTH)
    puts  geo_node.namespaces.any? ? 'Selective' : 'Full'

    print 'Database replication lag: '.rjust(COLUMN_WIDTH)
    puts "#{Gitlab::Geo::HealthCheck.db_replication_lag_seconds} seconds"

    print 'Last event ID seen from primary: '.rjust(COLUMN_WIDTH)
    last_event = Geo::EventLog.last
    if last_event
      print last_event&.id
      puts " (#{time_ago_in_words(last_event&.created_at)} ago)"

      print 'Last event ID processed by cursor: '.rjust(COLUMN_WIDTH)
      cursor_last_event_id = Geo::EventLogState.last_processed&.event_id

      if cursor_last_event_id
        print cursor_last_event_id
        last_cursor_event_date = Geo::EventLog.find_by(id: cursor_last_event_id)&.created_at
        print " (#{time_ago_in_words(last_cursor_event_date)} ago)" if last_cursor_event_date
        puts
      else
        puts 'N/A'
      end
    else
      puts 'N/A'
    end

    print 'Last status report was: '.rjust(COLUMN_WIDTH)

    if current_node_status.updated_at
      puts "#{time_ago_in_words(current_node_status.updated_at)} ago"
    else
      # Only primary node can create a status record in the database so if it does not exist
      # we get unsaved record where updated_at is nil
      puts "Never"
    end

    puts
  end

  def show_failed_value(value)
    print "#{value}".color(:red) + '/' if value > 0
  end

  def using_percentage(value)
    "(#{number_to_percentage(value.floor, precision: 0, strip_insignificant_zeros: true)})"
  end
end

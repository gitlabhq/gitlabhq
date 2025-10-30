# frozen_string_literal: true

click_house_database_names = %i[main]

namespace :gitlab do
  namespace :clickhouse do
    click_house_database_names.each do |database|
      namespace :drop do
        desc "GitLab | ClickHouse | Drop the #{database} database (options: VERSION=x, VERBOSE=false, SCOPE=y)"
        task database, [:skip_unless_configured] => :environment do |_t, args|
          if args[:skip_unless_configured] && !::ClickHouse::Client.database_configured?(database)
            puts "The '#{database}' ClickHouse database is not configured, cannot drop"
            next
          end

          enable_clickhouse_connectivity!
          drop_db(database)
        end
      end

      namespace :setup do
        desc "GitLab | ClickHouse | Setup the #{database} database"
        task database do
          enable_clickhouse_connectivity!
          create_db(database)
          migrate(:up, database)
        end
      end

      namespace :create do
        desc "GitLab | ClickHouse | Create the #{database} database (options: VERSION=x, VERBOSE=false, SCOPE=y)"
        task database, :environment do
          create_db(database)
        end
      end

      namespace :migrate do
        desc "GitLab | ClickHouse | Migrate the #{database} database (options: VERSION=x, VERBOSE=false, SCOPE=y)"
        task database, [:skip_unless_configured] => :environment do |_t, args|
          if args[:skip_unless_configured] && !::ClickHouse::Client.database_configured?(database)
            puts "The '#{database}' ClickHouse database is not configured, skipping migrations"
            next
          end

          enable_clickhouse_connectivity!
          migrate(:up, database)
        end
      end

      namespace :rollback do
        desc "GitLab | ClickHouse | Rolls the #{database} database back to the previous version " \
               "(specify steps w/ STEP=n)"
        task database => :environment do
          migrate(:down, database)
        end
      end
    end

    desc 'GitLab | ClickHouse | Migrate the databases (options: VERSION=x, VERBOSE=false, SCOPE=y)'
    task :migrate, [:skip_unless_configured] => :environment do |_t, args|
      click_house_database_names.each do |database|
        puts "Running gitlab:clickhouse:migrate:#{database} rake task"
        Rake::Task["gitlab:clickhouse:migrate:#{database}"].invoke(args[:skip_unless_configured])
      end
    end

    desc 'GitLab | ClickHouse | Drop the databases'
    task :drop, [:skip_unless_configured] => :environment do |_t, args|
      click_house_database_names.each do |database|
        puts "Running gitlab:clickhouse:drop:#{database} rake task"
        Rake::Task["gitlab:clickhouse:drop:#{database}"].invoke(args[:skip_unless_configured])
      end
    end

    desc 'GitLab | ClickHouse | Create the databases'
    task :create, [:skip_unless_configured] => :environment do
      click_house_database_names.each do |database|
        puts "Running gitlab:clickhouse:create:#{database} rake task"
        Rake::Task["gitlab:clickhouse:create:#{database}"].invoke
      end
    end

    desc 'GitLab | ClickHouse | Setup (create & migrate) the databases'
    task :setup, [:skip_unless_configured] => :environment do
      click_house_database_names.each do |database|
        puts "Running gitlab:clickhouse:setup:#{database} rake task"
        Rake::Task["gitlab:clickhouse:setup:#{database}"].invoke
      end
    end

    private

    def enable_clickhouse_connectivity!
      # The hostname of the ClickHouse server is set to "clickhouse" on CI.
      WebMock.allow_net_connect!(localhost: true, allow: %w[clickhouse]) if Rails.env.test? && ENV['DISABLE_WEBMOCK']
    end

    def drop_db(database)
      db = ClickHouse::Client.configuration.databases[database]
      ClickHouse::Client.configuration.databases[:default] = db.with_default_database

      ClickHouse::Client.execute("DROP DATABASE IF EXISTS #{db.database}", :default)
    end

    def create_db(database)
      main_db = ClickHouse::Client.configuration.databases[database]
      ClickHouse::Client.configuration.databases[:default] = main_db.with_default_database

      ClickHouse::Client.execute("CREATE DATABASE IF NOT EXISTS #{main_db.database}", :default)
    end

    def check_target_version
      return unless target_version

      version = ENV['VERSION']

      return if ClickHouse::Migration::MIGRATION_FILENAME_REGEXP.match?(version) || /\A\d+\z/.match?(version)

      raise "Invalid format of target version: `VERSION=#{version}`"
    end

    def target_version
      ENV['VERSION'].to_i if ENV['VERSION'] && !ENV['VERSION'].empty?
    end

    def migrate(direction, database)
      require_relative '../../../../lib/click_house/migration_support/schema_migration'
      require_relative '../../../../lib/click_house/migration_support/migration_context'
      require_relative '../../../../lib/click_house/migration_support/migrator'
      require_relative '../../../../lib/click_house/schema_migrations'

      check_target_version

      scope = ENV['SCOPE']
      step = ENV['STEP'] ? Integer(ENV['STEP']) : nil
      step = 1 if step.nil? && direction == :down
      raise ArgumentError, 'STEP should be a positive number' if step.present? && step < 1

      verbose_was = ::ClickHouse::Migration.verbose
      ClickHouse::Migration.verbose = ENV['VERBOSE'] ? ENV['VERBOSE'] != 'false' : true

      migrations_paths = ::ClickHouse::MigrationSupport::Migrator.migrations_paths(database)
      connection = ::ClickHouse::Connection.new(database)
      schema_migration = ClickHouse::MigrationSupport::SchemaMigration.new(connection)
      schema_migration.ensure_table

      migration_context = ClickHouse::MigrationSupport::MigrationContext.new(
        connection,
        migrations_paths,
        schema_migration
      )

      migration_context.public_send(direction, target_version, step) do |migration|
        scope.blank? || scope == migration.scope
      end

      # Save migration files reflecting current migration state
      # This ensures files are added for new migrations and removed for rolled back ones
      ClickHouse::SchemaMigrations.touch_all(connection, database)
      Rake::Task["gitlab:clickhouse:schema:dump:#{database}"].invoke unless Rails.env.test?
    ensure
      ClickHouse::Migration.verbose = verbose_was
    end
  end
end

# frozen_string_literal: true

click_house_database_names = %i[main]

namespace :gitlab do
  namespace :clickhouse do
    namespace :migrate do
      click_house_database_names.each do |database|
        desc "GitLab | ClickHouse | Migrate the #{database} database (options: VERSION=x, VERBOSE=false, SCOPE=y)"
        task database, [:skip_unless_configured] => :environment do |_t, args|
          if args[:skip_unless_configured] && !::ClickHouse::Client.database_configured?(database)
            puts "The '#{database}' ClickHouse database is not configured, skipping migrations"
            next
          end

          migrate(:up, database)
        end
      end
    end

    namespace :rollback do
      click_house_database_names.each do |database|
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

    private

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

      migration_context = ClickHouse::MigrationSupport::MigrationContext.new(connection, migrations_paths,
        schema_migration)

      migrations_ran = migration_context.public_send(direction, target_version, step) do |migration|
        scope.blank? || scope == migration.scope
      end

      puts('No migrations ran.') unless migrations_ran&.any?
    ensure
      ClickHouse::Migration.verbose = verbose_was
    end
  end
end

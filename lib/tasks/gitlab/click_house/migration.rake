# frozen_string_literal: true

namespace :gitlab do
  namespace :clickhouse do
    task :prepare_schema_migration_table, [:database] => :environment do |_t, args|
      require_relative '../../../../lib/click_house/migration_support/schema_migration'

      ClickHouse::MigrationSupport::SchemaMigration.create_table(args.database&.to_sym || :main)
    end

    desc 'GitLab | ClickHouse | Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=y)'
    task migrate: [:prepare_schema_migration_table] do
      migrate(:up)
    end

    desc 'GitLab | ClickHouse | Rolls the schema back to the previous version (specify steps w/ STEP=n)'
    task rollback: [:prepare_schema_migration_table] do
      migrate(:down)
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

    def migrate(direction)
      require_relative '../../../../lib/click_house/migration_support/schema_migration'
      require_relative '../../../../lib/click_house/migration_support/migration_context'
      require_relative '../../../../lib/click_house/migration_support/migrator'

      check_target_version

      scope = ENV['SCOPE']
      step = ENV['STEP'] ? Integer(ENV['STEP']) : nil
      step = 1 if step.nil? && direction == :down
      raise ArgumentError, 'STEP should be a positive number' if step.present? && step < 1

      verbose_was = ClickHouse::Migration.verbose
      ClickHouse::Migration.verbose = ENV['VERBOSE'] ? ENV['VERBOSE'] != 'false' : true

      migrations_paths = ClickHouse::MigrationSupport::Migrator.migrations_paths
      schema_migration = ClickHouse::MigrationSupport::SchemaMigration
      migration_context = ClickHouse::MigrationSupport::MigrationContext.new(migrations_paths, schema_migration)
      migrations_ran = migration_context.public_send(direction, target_version, step) do |migration|
        scope.blank? || scope == migration.scope
      end

      puts('No migrations ran.') unless migrations_ran&.any?
    ensure
      ClickHouse::Migration.verbose = verbose_was
    end
  end
end

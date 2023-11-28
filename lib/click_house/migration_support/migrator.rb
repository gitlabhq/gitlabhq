# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class Migrator
      include ::Gitlab::ExclusiveLeaseHelpers

      class << self
        attr_accessor :migrations_paths
      end

      attr_accessor :logger

      LEASE_KEY = 'click_house:migrations'
      RETRY_DELAY = ->(num) { 0.2.seconds * (num**2) }
      LOCK_DURATION = 1.hour

      self.migrations_paths = ["db/click_house/migrate"]

      def initialize(
        direction, migrations, schema_migration, target_version = nil, step = nil,
        logger = Gitlab::AppLogger
      )
        @direction         = direction
        @target_version    = target_version
        @step              = step
        @migrated_versions = {}
        @migrations        = migrations
        @schema_migration  = schema_migration
        @logger            = logger

        validate(@migrations)
      end

      def current_version
        @migrated_versions.values.flatten.max || 0
      end

      def current_migration
        migrations.detect { |m| m.version == current_version }
      end
      alias_method :current, :current_migration

      def migrate
        in_lock(LEASE_KEY, ttl: LOCK_DURATION, retries: 5, sleep_sec: RETRY_DELAY) do
          migrate_without_lock
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError => e
        raise ClickHouse::MigrationSupport::LockError, e.message
      end

      def runnable
        runnable = migrations[start..finish]

        if up?
          runnable = runnable.reject { |m| ran?(m) }
        else
          # skip the last migration if we're headed down, but not ALL the way down
          runnable.pop if target
          runnable = runnable.find_all { |m| ran?(m) }
        end

        runnable = runnable.take(@step) if @step && !@target_version
        runnable
      end

      def migrations
        down? ? @migrations.reverse : @migrations.sort_by(&:version)
      end

      def pending_migrations(database)
        already_migrated = migrated(database)

        migrations.reject { |m| already_migrated.include?(m.version) }
      end

      def migrated(database)
        @migrated_versions[database] || load_migrated(database)
      end

      def load_migrated(database)
        ensure_schema_migration_table(database)

        @migrated_versions[database] = Set.new(@schema_migration.all_versions(database).map(&:to_i))
      end

      private

      def ensure_schema_migration_table(database)
        return if @migrated_versions[database]

        @schema_migration.create_table(database)
      end

      # Used for running a specific migration.
      def run_without_lock
        migration = migrations.detect { |m| m.version == @target_version }

        raise ClickHouse::MigrationSupport::UnknownMigrationVersionError, @target_version if migration.nil?

        execute_migration(migration)
      end

      # Used for running multiple migrations up to or down to a certain value.
      def migrate_without_lock
        raise ClickHouse::MigrationSupport::UnknownMigrationVersionError, @target_version if invalid_target?

        runnable.each(&method(:execute_migration)) # rubocop: disable Performance/MethodObjectAsBlock -- Execute through proxy
      end

      def ran?(migration)
        migrated(migration.database).include?(migration.version.to_i)
      end

      # Return true if a valid version is not provided.
      def invalid_target?
        return unless @target_version
        return if @target_version == 0

        !target
      end

      def execute_migration(migration)
        database = migration.database

        return if down? && migrated(database).exclude?(migration.version.to_i)
        return if up? && migrated(database).include?(migration.version.to_i)

        logger.info "Migrating to #{migration.name} (#{migration.version})" if logger

        migration.migrate(@direction)
        record_version_state_after_migrating(database, migration.version)
      rescue StandardError => e
        msg = "An error has occurred, all later migrations canceled:\n\n#{e}"
        raise StandardError, msg, e.backtrace
      end

      def target
        migrations.detect { |m| m.version == @target_version }
      end

      def finish
        migrations.index(target) || (migrations.size - 1)
      end

      def start
        up? ? 0 : (migrations.index(current) || 0)
      end

      def validate(migrations)
        name, = migrations.group_by(&:name).find { |_, v| v.length > 1 }
        raise ClickHouse::MigrationSupport::DuplicateMigrationNameError, name if name

        version, = migrations.group_by(&:version).find { |_, v| v.length > 1 }
        raise ClickHouse::MigrationSupport::DuplicateMigrationVersionError, version if version
      end

      def record_version_state_after_migrating(database, version)
        if down?
          migrated(database).delete(version)
          @schema_migration.create!(database, version: version.to_s, active: 0)
        else
          migrated(database) << version
          @schema_migration.create!(database, version: version.to_s)
        end
      end

      def up?
        @direction == :up
      end

      def down?
        @direction == :down
      end
    end
  end
end

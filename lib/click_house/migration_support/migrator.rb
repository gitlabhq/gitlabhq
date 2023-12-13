# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class Migrator
      attr_accessor :logger

      def self.migrations_paths(database_name)
        File.join("db/click_house/migrate", database_name.to_s)
      end

      def initialize(
        direction, migrations, schema_migration, target_version = nil, step = nil,
        logger = Gitlab::AppLogger
      )
        @direction         = direction
        @target_version    = target_version
        @step              = step
        @migrations        = migrations
        @schema_migration  = schema_migration
        @logger            = logger

        validate(@migrations)
      end

      def current_version
        migrated.max || 0
      end

      def current_migration
        migrations.detect { |m| m.version == current_version }
      end
      alias_method :current, :current_migration

      def migrate
        ClickHouse::MigrationSupport::ExclusiveLock.execute_migration do
          migrate_without_lock
        end
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

      def migrated
        @migrated_versions || load_migrated
      end

      def load_migrated
        @migrated_versions = Set.new(@schema_migration.all_versions.map(&:to_i))
      end

      private

      # Used for running multiple migrations up to or down to a certain value.
      def migrate_without_lock
        raise ClickHouse::MigrationSupport::Errors::UnknownMigrationVersionError, @target_version if invalid_target?

        runnable.each(&method(:execute_migration)) # rubocop: disable Performance/MethodObjectAsBlock -- Execute through proxy
      end

      def ran?(migration)
        migrated.include?(migration.version.to_i)
      end

      # Return true if a valid version is not provided.
      def invalid_target?
        return unless @target_version
        return if @target_version == 0

        !target
      end

      def execute_migration(migration)
        return if down? && migrated.exclude?(migration.version.to_i)
        return if up? && migrated.include?(migration.version.to_i)

        logger.info "Migrating to #{migration.name} (#{migration.version})" if logger

        migration.migrate(@direction)
        record_version_state_after_migrating(migration.version)
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
        raise ClickHouse::MigrationSupport::Errors::DuplicateMigrationNameError, name if name

        version, = migrations.group_by(&:version).find { |_, v| v.length > 1 }
        raise ClickHouse::MigrationSupport::Errors::DuplicateMigrationVersionError, version if version
      end

      def record_version_state_after_migrating(version)
        if down?
          migrated.delete(version)
          @schema_migration.create!(version: version.to_s, active: 0)
        else
          migrated << version
          @schema_migration.create!(version: version.to_s)
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

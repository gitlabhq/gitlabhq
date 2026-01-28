# frozen_string_literal: true

module Keeps
  module OverdueFinalizeBackgroundMigrations
    class OutdatedMigrationChecker
      # Migration files older than this threshold will force push even if MR has approvals
      MIGRATION_AGE_THRESHOLD_WEEKS = 3

      def initialize(logger: nil)
        @logger = logger || Logger.new(nil)
      end

      def existing_migration_timestamp_outdated?(identifiers)
        migration_timestamp = find_existing_remote_migration_timestamp(identifiers)
        return false unless migration_timestamp

        migration_time = Time.strptime(migration_timestamp, '%Y%m%d%H%M%S')

        # Force push if migration is older than the age threshold
        return true if migration_time < MIGRATION_AGE_THRESHOLD_WEEKS.weeks.ago

        # Force push if migration timestamp is before the cutoff milestone
        migration_time < cutoff_milestone_timestamp
      end

      private

      def find_existing_remote_migration_timestamp(identifiers)
        branch_name = ::Gitlab::Housekeeper::Git.branch_name(identifiers)
        git = ::Gitlab::Housekeeper::Git.new(logger: @logger)

        files = git.remote_branch_changed_files(branch_name, 'db/schema_migrations/')

        # Find schema_migration file (format: db/schema_migrations/20250918232145)
        schema_migration_file = files.find { |f| f.match?(%r{db/schema_migrations/\d{14}$}) }
        return unless schema_migration_file

        # Extract timestamp from filename
        File.basename(schema_migration_file)
      rescue ::Gitlab::Housekeeper::Shell::Error
        nil
      end

      def cutoff_milestone_timestamp
        @cutoff_milestone_timestamp ||= begin
          # Get the minimum schema version (e.g., "17.4") and convert to approximate timestamp
          # GitLab releases are on the third Thursday of each month
          min_version = ::Gitlab::Database.min_schema_gitlab_version
          major = min_version.major
          minor = min_version.minor

          # 18.8 was released in January 2026
          base_year = 2026
          base_month = 1 # January 2026 was 18.8
          base_major = 18
          base_minor = 8

          months_since_base = ((major - base_major) * 12) + (minor - base_minor)
          release_month = Date.new(base_year, base_month, 1) + months_since_base.months

          # Find the third Thursday of the release month
          third_thursday_of_month(release_month.year, release_month.month).to_time(:utc)
        end
      end

      def third_thursday_of_month(year, month)
        first_day = Date.new(year, month, 1)
        # Find the first Thursday (wday 4)
        first_thursday = first_day + ((4 - first_day.wday) % 7)
        # Third Thursday is 2 weeks after the first
        first_thursday + 14
      end
    end
  end
end

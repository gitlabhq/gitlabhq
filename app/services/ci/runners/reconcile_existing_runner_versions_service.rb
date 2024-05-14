# frozen_string_literal: true

module Ci
  module Runners
    class ReconcileExistingRunnerVersionsService
      VERSION_BATCH_SIZE = 100

      def execute
        insert_result = insert_runner_versions
        total_deleted = cleanup_runner_versions(insert_result[:versions_from_runners])
        total_updated = update_status_on_outdated_runner_versions(insert_result[:versions_from_runners])

        ServiceResponse.success(payload: {
          total_inserted: insert_result[:new_record_count],
          total_updated: total_updated,
          total_deleted: total_deleted
        })
      end

      private

      def upgrade_check
        @runner_upgrade_check ||= Gitlab::Ci::RunnerUpgradeCheck.new(::Gitlab::VERSION)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def insert_runner_versions
        versions_from_runners = Set[]
        new_record_count = 0
        Ci::RunnerManager.distinct_each_batch(column: :version, of: VERSION_BATCH_SIZE) do |version_batch|
          batch_versions = version_batch.pluck(:version).to_set
          versions_from_runners += batch_versions

          # Avoid hitting primary DB
          already_existing_versions = Ci::RunnerVersion.where(version: batch_versions).pluck(:version)
          new_versions = batch_versions - already_existing_versions

          if new_versions.any?
            new_record_count += Ci::RunnerVersion.insert_all(
              new_versions.map { |v| { version: v } },
              returning: :version,
              unique_by: :version).count
          end
        end

        { versions_from_runners: versions_from_runners, new_record_count: new_record_count }
      end

      def cleanup_runner_versions(versions_from_runners)
        Ci::RunnerVersion.where.not(version: versions_from_runners).delete_all
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def outdated_runner_versions
        Ci::RunnerVersion.potentially_outdated
      end

      def update_status_on_outdated_runner_versions(versions_from_runners)
        total_updated = 0

        outdated_runner_versions.each_batch(of: VERSION_BATCH_SIZE) do |version_batch|
          updated = version_batch
            .select { |runner_version| versions_from_runners.include?(runner_version['version']) }
            .filter_map { |runner_version| runner_version_with_updated_status(runner_version) }

          if updated.any?
            total_updated += Ci::RunnerVersion.upsert_all(updated, unique_by: :version).count
          end
        end

        total_updated
      end

      def runner_version_with_updated_status(runner_version)
        _, new_status = upgrade_check.check_runner_upgrade_suggestion(runner_version.version)

        if new_status != :error && new_status != runner_version.status.to_sym
          {
            version: runner_version.version,
            status: Ci::RunnerVersion.statuses[new_status]
          }
        end
      end
    end
  end
end

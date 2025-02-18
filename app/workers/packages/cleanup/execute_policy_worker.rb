# frozen_string_literal: true

module Packages
  module Cleanup
    class ExecutePolicyWorker
      include ApplicationWorker
      include CronjobChildWorker
      include LimitedCapacity::Worker
      include Gitlab::Utils::StrongMemoize

      data_consistency :sticky
      queue_namespace :package_cleanup
      feature_category :package_registry
      urgency :low
      worker_resource_boundary :unknown
      idempotent!

      COUNTS_KEYS = %i[
        marked_package_files_total_count
        unique_package_id_and_file_name_total_count
      ].freeze

      def perform_work
        return unless next_policy

        log_extra_metadata_on_done(:project_id, next_policy.project_id)
        result = ::Packages::Cleanup::ExecutePolicyService.new(next_policy).execute

        if result.success?
          timeout = !!result.payload[:timeout]
          counts = result.payload[:counts]
          log_extra_metadata_on_done(:execution_timeout, timeout)
          COUNTS_KEYS.each do |count_key|
            log_extra_metadata_on_done(count_key, counts[count_key])
          end
        end
      end

      def remaining_work_count
        ::Packages::Cleanup::Policy.runnable
                                   .limit(max_running_jobs + 1)
                                   .count
      end

      def max_running_jobs
        ::Gitlab::CurrentSettings.package_registry_cleanup_policies_worker_capacity
      end

      private

      def next_policy
        strong_memoize(:next_policy) do
          ::Packages::Cleanup::Policy.transaction do
            # the #lock call is specific to this worker
            # rubocop: disable CodeReuse/ActiveRecord
            policy = ::Packages::Cleanup::Policy.runnable
                                                .limit(1)
                                                .lock('FOR UPDATE SKIP LOCKED')
                                                .first
            # rubocop: enable CodeReuse/ActiveRecord

            next nil unless policy

            policy.set_next_run_at
            policy.save!

            policy
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Packages
  module Cleanup
    class DeleteOrphanedDependenciesWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky
      feature_category :package_registry
      urgency :low
      idempotent!

      # This cron worker is executed at an interval of 10 minutes and should not run for
      # more than 2 minutes nor process more than 10 batches.
      MAX_RUN_TIME = 2.minutes
      MAX_BATCHES = 10
      BATCH_SIZE = 100
      LAST_PROCESSED_PACKAGES_DEPENDENCY_REDIS_KEY = 'last_processed_packages_dependency_id'
      REDIS_EXPIRATION_TIME = 2.hours.to_i

      def perform
        start_time

        dependency_id = last_processed_dependency_id
        batches_count = 0
        deleted_rows_count = 0

        ::Packages::Dependency.id_in(dependency_id..).each_batch(of: BATCH_SIZE) do |batch|
          batches_count += 1
          deleted_rows_count += batch.orphaned.delete_all

          if batches_count == MAX_BATCHES || over_time?
            save_last_processed_dependency_id(batch.maximum(:id))
            break
          end
        end

        log_extra_metadata(deleted_rows_count)
        reset_last_processed_dependency_id if batches_count < MAX_BATCHES && !over_time?
      end

      private

      def start_time
        @start_time ||= ::Gitlab::Metrics::System.monotonic_time
      end

      def over_time?
        (::Gitlab::Metrics::System.monotonic_time - start_time) > MAX_RUN_TIME
      end

      def save_last_processed_dependency_id(dependency_id)
        with_redis do |redis|
          redis.set(LAST_PROCESSED_PACKAGES_DEPENDENCY_REDIS_KEY, dependency_id, ex: REDIS_EXPIRATION_TIME)
        end
      end

      def last_processed_dependency_id
        with_redis do |redis|
          redis.get(LAST_PROCESSED_PACKAGES_DEPENDENCY_REDIS_KEY).to_i
        end
      end

      def reset_last_processed_dependency_id
        with_redis do |redis|
          redis.del(LAST_PROCESSED_PACKAGES_DEPENDENCY_REDIS_KEY)
        end
      end

      def with_redis(&block)
        Gitlab::Redis::SharedState.with(&block) # rubocop:disable CodeReuse/ActiveRecord
      end

      def log_extra_metadata(deleted_rows_count)
        log_extra_metadata_on_done(:last_processed_packages_dependency_id, last_processed_dependency_id)
        log_extra_metadata_on_done(:deleted_rows_count, deleted_rows_count)
      end
    end
  end
end

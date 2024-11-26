# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        class DeduplicatesWhenScheduling < Base
          extend ::Gitlab::Utils::Override
          include ::Gitlab::Utils::StrongMemoize

          override :initialize
          def initialize(duplicate_job)
            @duplicate_job = duplicate_job
          end

          override :schedule
          def schedule(job)
            return false if deduplicate?(job)

            # Delete signaling key as the job will be enqueued and no
            # rescheduling is needed on the server-middleware.
            duplicate_job.clear_signaling_key

            yield
          end

          override :perform
          def perform(job)
            update_job_wal_location!(job)
          end

          private

          def deduplicate?(job)
            # no redis operations, hence this can be checked outside of the lease
            return false unless deduplicatable_job?

            return false unless check! && duplicate_job.duplicate?

            job['duplicate-of'] = duplicate_job.existing_jid

            return false unless duplicate_job.idempotent? # only dedup idempotent jobs

            duplicate_job.update_latest_wal_location!

            Gitlab::SidekiqLogging::DeduplicationLogger.instance.deduplicated_log(
              job, strategy_name, duplicate_job.options)

            true
          end

          def update_job_wal_location!(job)
            job['dedup_wal_locations'] = duplicate_job.latest_wal_locations if duplicate_job.latest_wal_locations.present?
          end

          def deduplicatable_job?
            return false if scheduled_deferred_job?

            !duplicate_job.scheduled? || duplicate_job.options[:including_scheduled]
          end

          # we do not deduplicate deferred perform_in/perform_at.
          # note that the schedule enq will push the jobs out of the zset with `deferred: true`
          def scheduled_deferred_job?
            duplicate_job.scheduled? && duplicate_job.deferred?
          end

          def check!
            duplicate_job.check!(expiry)
          end

          def expiry
            strong_memoize(:expiry) do
              next duplicate_job.duplicate_key_ttl unless duplicate_job.scheduled?

              time_diff = [
                duplicate_job.scheduled_at.to_i - Time.now.to_i,
                0
              ].max

              time_diff + duplicate_job.duplicate_key_ttl
            end
          end
        end
      end
    end
  end
end

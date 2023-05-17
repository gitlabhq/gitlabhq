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
            if deduplicatable_job? && check! && duplicate_job.duplicate?
              job['duplicate-of'] = duplicate_job.existing_jid

              if duplicate_job.idempotent?
                duplicate_job.update_latest_wal_location!
                duplicate_job.set_deduplicated_flag!(expiry)

                Gitlab::SidekiqLogging::DeduplicationLogger.instance.deduplicated_log(
                  job, strategy_name, duplicate_job.options)
                return false
              end
            end

            yield
          end

          override :perform
          def perform(job)
            update_job_wal_location!(job)
          end

          private

          def update_job_wal_location!(job)
            job['dedup_wal_locations'] = duplicate_job.latest_wal_locations if duplicate_job.latest_wal_locations.present?
          end

          def deduplicatable_job?
            !duplicate_job.scheduled? || duplicate_job.options[:including_scheduled]
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

# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      module Usages
        # Component usage is defined as the number of unique `used_by_project_id`s in the table
        # `p_catalog_resource_component_usages` for a given scope.
        #
        # This aggregator is intended to be run in a scheduled cron job. It implements a "continue later"
        # mechanism with a Redis cursor, which enables the work to continue from where it was last interrupted
        # on each run. It iterates through the target table in batches, in order of ID ascending. For each
        # target ID, it collects the usage count using `distinct_each_batch` for the given usage window.
        # We collect the count in Rails because the SQL query `COUNT(DISTINCT(*))` is not performant when the
        # data volume is large.
        #
        # RUNTIME: The actual total runtime will be longer than MAX_RUNTIME because
        #          it depends on the execution time of `&usage_counts_block`.
        # EXCLUSIVE LEASE: This aggregator is protected from parallel processing with an exclusive lease guard.
        # WORKER: The worker running this service should be scheduled at the same cadence as MAX_RUNTIME, with:
        #         deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: WORKER_DEDUP_TTL
        # STOPPING: When the aggregator's cursor advances past the max target_id, it resets to 0. This means
        #           it may reprocess targets that have already been processed for the given usage window.
        #           To minimize redundant reprocessing, you should prevent the aggregator from running once it
        #           meets a certain stop condition (e.g. when all targets have been marked as "processed").
        #
        ##### Usage
        #
        # each_batch:
        #   - Yields each batch of `usage_counts` to the given block. The block should:
        #     - Be able to handle targets that might be reprocessed multiple times.
        #     - Not exceed 1 minute in execution time.
        #   - `usage_counts` format: { target_object1 => 100, target_object2 => 200, ... }
        #   - If the lease is obtained, returns a Result containing `total_targets_completed` and
        #     `cursor_attributes`. Otherwise, returns nil.
        #
        # Example:
        #  return if done_processing?
        #
        #  aggregator = Gitlab::Ci::Components::Usages::Aggregator.new(
        #    target_model: Ci::Catalog::Resource,
        #    group_by_column: :catalog_resource_id,
        #    usage_start_date: Date.today - 30.days,
        #    usage_end_date: Date.today - 1.day,
        #    lease_key: 'my_aggregator_service_lease_key'
        #  )
        #
        #  result = aggregator.each_batch do |usage_counts|
        #    # Bulk update usage counts in the database
        #  end
        #
        ##### Parameters
        #
        # target_model: Target model to iterate through. Model class should contain `include EachBatch`.
        # group_by_column: This should be the usage table's foreign key of the target_model.
        # usage_start_date & usage_end_date: Date objects specifiying the window of usage data to aggregate.
        # lease_key: Used for obtaining an exclusive lease. Also used as part of the cursor Redis key.
        #
        # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required for data processing
        class Aggregator
          include ExclusiveLeaseGuard

          Result = Struct.new(:total_targets_completed, :cursor_attributes, keyword_init: true)

          TARGET_BATCH_SIZE = 1000
          DISTINCT_USAGE_BATCH_SIZE = 100
          MAX_RUNTIME = 4.minutes # Should be >= job scheduling frequency so there is no gap between job runs

          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155001#note_1941066672
          # Includes extra time (1.minute) to execute `&usage_counts_block`
          WORKER_DEDUP_TTL = MAX_RUNTIME + 1.minute
          LEASE_TIMEOUT = 10.minutes

          def initialize(target_model:, group_by_column:, usage_start_date:, usage_end_date:, lease_key:)
            @target_model = target_model
            @group_by_column = group_by_column
            @lease_key = lease_key # Used by ExclusiveLeaseGuard
            @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

            @cursor = Aggregators::Cursor.new(
              redis_key: "#{lease_key}:cursor",
              target_model: target_model,
              usage_window: Aggregators::Cursor::Window.new(usage_start_date, usage_end_date)
            )
          end

          def each_batch(&usage_counts_block)
            try_obtain_lease do
              total_targets_completed = process_targets(&usage_counts_block)

              Result.new(total_targets_completed: total_targets_completed, cursor_attributes: cursor.attributes)
            end
          end

          private

          attr_reader :target_model, :group_by_column, :cursor, :runtime_limiter

          def process_targets
            # Restore the scope from cursor so we can resume from the last run. `cursor.target_id` is 0
            # when the Redis cursor is first initialized or when it advances past the max target ID.
            restored_target_scope = target_model.where('id >= ?', cursor.target_id)
            total_targets_completed = 0

            restored_target_scope.each_batch(of: TARGET_BATCH_SIZE) do |targets_relation|
              usage_counts = aggregate_usage_counts(targets_relation)

              yield usage_counts if usage_counts.present?

              total_targets_completed += usage_counts.length
              break if runtime_limiter.over_time?
            end

            cursor.advance unless cursor.interrupted?
            cursor.save!

            total_targets_completed
          end

          def aggregate_usage_counts(targets_relation)
            usage_counts = {}

            targets_relation.order(:id).each do |target|
              # When target.id is different from the cursor's target_id, it
              # resets last_usage_count and last_used_by_project_id to 0.
              cursor.target_id = target.id

              usage_scope = ::Ci::Catalog::Resources::Components::Usage
                              .where(group_by_column => cursor.target_id)
                              .where(used_date: cursor.usage_window.start_date..cursor.usage_window.end_date)

              # Restore the scope from cursor so we can resume from the last run if interrupted
              restored_usage_scope = usage_scope.where('used_by_project_id > ?', cursor.last_used_by_project_id)
              usage_counts[target] = cursor.last_usage_count

              restored_usage_scope
                .distinct_each_batch(column: :used_by_project_id, of: DISTINCT_USAGE_BATCH_SIZE) do |usages_relation|
                count = usages_relation.count
                usage_counts[target] += count

                # If we're over time and count == batch size, it means there is likely another batch
                # to process for the current target, so the usage count is incomplete. We store the
                # last used_by_project_id and count so that we can resume counting on the next run.
                if runtime_limiter.over_time? && count == DISTINCT_USAGE_BATCH_SIZE
                  cursor.interrupt!(
                    last_used_by_project_id: usages_relation.maximum(:used_by_project_id).to_i,
                    last_usage_count: usage_counts[target]
                  )

                  usage_counts.delete(target) # Remove the incomplete count
                  break
                end
              end

              break if runtime_limiter.over_time?
            end

            usage_counts
          end

          def lease_timeout
            LEASE_TIMEOUT
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end

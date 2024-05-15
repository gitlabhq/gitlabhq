# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      module Usages
        # Component usage is defined as the number of unique `used_by_project_id`s in the table
        # `p_catalog_resource_component_usages` for a given scope.
        #
        # This aggregator iterates through the target scope in batches. For each target ID, it collects
        # the usage count using `distinct_each_batch` for the given usage window. Since this process can
        # be interrupted when it reaches MAX_RUNTIME, we utilize a Redis cursor so the aggregator can
        # resume from where it left off on each run. We collect the count in Rails because the SQL query
        # `COUNT(DISTINCT(*))` is not performant when the dataset is large.
        #
        # RUNTIME: The actual total runtime will be slightly longer than MAX_RUNTIME because
        #          it depends on the execution time of `&usage_counts_block`.
        # EXCLUSIVE LEASE: This aggregator is protected from parallel processing with an exclusive lease guard.
        # WORKER: The worker running this service should be scheduled at the same cadence as MAX_RUNTIME, with:
        #         deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: LEASE_TIMEOUT
        #
        ##### Usage
        #
        # each_batch:
        #   - Yields each batch of `usage_counts` to the given block.
        #   - The block should be able to handle targets that might be reprocessed multiple times.
        #   - `usage_counts` format: { target_object1 => 100, target_object2 => 200, ... }
        #   - If the lease is obtained, returns a Result containing the `cursor` object and
        #     `total_targets_completed`. Otherwise, returns nil.
        #
        # Example:
        #  aggregator = Gitlab::Ci::Components::Usages::Aggregator.new(
        #    target_scope: Ci::Catalog::Resource.scope_to_get_only_unprocessed_targets,
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
        # target_scope:
        #   - ActiveRecord relation to retrieve the target IDs. Processed in order of ID ascending.
        #   - The target model class should have `include EachBatch`.
        #   - When cursor.target_id gets reset to 0, the aggregator may reprocess targets that have
        #     already been processed for the given usage window.  To minimize redundant reprocessing,
        #     add a limiting condition to the target scope so it only retrieves unprocessed targets.
        # group_by_column: This should be the usage table's foreign key of the target_scope.
        # usage_start_date & usage_end_date: Date objects specifiying the window of usage data to aggregate.
        # lease_key: Used for obtaining an exclusive lease. Also used as part of the cursor Redis key.
        #
        # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required for data processing
        class Aggregator
          include Gitlab::Utils::StrongMemoize
          include ExclusiveLeaseGuard

          Result = Struct.new(:cursor, :total_targets_completed, keyword_init: true)

          TARGET_BATCH_SIZE = 1000
          DISTINCT_USAGE_BATCH_SIZE = 100
          MAX_RUNTIME = 4.minutes # Should be >= job scheduling frequency so there is no gap between job runs
          LEASE_TIMEOUT = 5.minutes # Should be MAX_RUNTIME + extra time to execute `&usage_counts_block`

          def initialize(target_scope:, group_by_column:, usage_start_date:, usage_end_date:, lease_key:)
            @target_scope = target_scope
            @group_by_column = group_by_column
            @lease_key = lease_key # Used by ExclusiveLeaseGuard
            @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

            @cursor = Aggregators::Cursor.new(
              redis_key: "#{lease_key}:cursor",
              target_scope: target_scope,
              usage_window: Aggregators::Cursor::Window.new(usage_start_date, usage_end_date)
            )
          end

          def each_batch(&usage_counts_block)
            try_obtain_lease do
              total_targets_completed = process_targets(&usage_counts_block)

              Result.new(cursor: cursor, total_targets_completed: total_targets_completed)
            end
          end

          private

          attr_reader :target_scope, :group_by_column, :cursor, :runtime_limiter

          def process_targets
            # Restore the scope from cursor so we can resume from the last run
            restored_target_scope = target_scope.where('id >= ?', cursor.target_id)
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

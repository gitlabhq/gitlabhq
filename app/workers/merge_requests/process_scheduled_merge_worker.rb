# frozen_string_literal: true

module MergeRequests
  class ProcessScheduledMergeWorker # rubocop:disable Scalability/IdempotentWorker -- time dependent queries can't be idempotent
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- this is a cronjob

    include CronjobQueue
    include ::Gitlab::ExclusiveLeaseHelpers

    LOCK_RETRY = 3
    LOCK_TTL = 5.minutes
    DELAY = 7.seconds
    BATCH_SIZE = 500

    feature_category :code_review_workflow
    worker_resource_boundary :cpu

    def perform
      in_lock(lock_key, **lock_params) do
        # rubocop:disable CodeReuse/ActiveRecord -- using keyset pagination with custom order for better performance
        order = Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'merge_after',
            order_expression: MergeRequests::MergeSchedule.arel_table[:merge_after].asc,
            nullable: :not_nullable
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'merge_request_id',
            order_expression: MergeRequests::MergeSchedule.arel_table[:merge_request_id].asc,
            nullable: :not_nullable
          )
        ])

        scope = MergeRequests::MergeSchedule
          .where(merge_after: ..Time.zone.now)
          .order(order)
          .select(:merge_after, :merge_request_id)

        iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)

        iteration = 0
        iterator.each_batch(of: BATCH_SIZE) do |records|
          loaded_records = MergeRequest
            .with_auto_merge_enabled
            .where(id: records.to_a.pluck(:merge_request_id))

          enqueue_auto_merge_process_worker(loaded_records, iteration)
          iteration += 1
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end

    private

    def lock_key
      self.class.name.underscore
    end

    def lock_params
      {
        ttl: LOCK_TTL,
        retries: LOCK_RETRY
      }
    end

    def enqueue_auto_merge_process_worker(merge_requests, index)
      AutoMergeProcessWorker.bulk_perform_in_with_contexts(
        [1, index * DELAY].max,
        merge_requests,
        arguments_proc: ->(merge_request) { [{ 'merge_request_id' => merge_request.id }] },
        context_proc: ->(merge_request) { { project: merge_request.project, user: merge_request.merge_user } }
      )
    end
  end
end

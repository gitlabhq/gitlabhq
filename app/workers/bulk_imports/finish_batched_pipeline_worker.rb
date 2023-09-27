# frozen_string_literal: true

module BulkImports
  class FinishBatchedPipelineWorker
    include ApplicationWorker
    include ExceptionBacktrace

    REQUEUE_DELAY = 5.seconds

    idempotent!
    deduplicate :until_executing
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :importers

    version 2

    def perform(pipeline_tracker_id)
      @tracker = Tracker.find(pipeline_tracker_id)

      return unless tracker.batched?
      return unless tracker.started?
      return re_enqueue if import_in_progress?

      if tracker.stale?
        tracker.batches.map(&:fail_op!)
        tracker.fail_op!
      else
        tracker.finish!
      end

    ensure
      # This is needed for in-flight migrations.
      # It will be remove in https://gitlab.com/gitlab-org/gitlab/-/issues/426299
      ::BulkImports::EntityWorker.perform_async(tracker.entity.id) if job_version.nil?
    end

    private

    attr_reader :tracker

    def re_enqueue
      self.class.perform_in(REQUEUE_DELAY, tracker.id)
    end

    def import_in_progress?
      tracker.batches.any?(&:started?)
    end
  end
end

# frozen_string_literal: true

# This worker regularly schedules projects with configured CI retention policies
# to get their old pipelines removed.
module Ci
  class ScheduleOldPipelinesRemovalCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

    urgency :low
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    feature_category :continuous_integration
    data_consistency :sticky

    def perform
      cleanup_queue.enqueue_projects!

      Ci::DestroyOldPipelinesWorker.perform_with_capacity
    end

    private

    def cleanup_queue
      @cleanup_queue ||= Ci::RetentionPolicies::ProjectsCleanupQueue.instance
    end
  end
end

# frozen_string_literal: true

module TasksToBeDone
  class CreateWorker
    include ApplicationWorker

    data_consistency :always
    idempotent!
    feature_category :onboarding
    urgency :low
    worker_resource_boundary :cpu

    def perform(member_task_id, current_user_id, assignee_ids = [])
      # no-op removing
      # https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
    end
  end
end

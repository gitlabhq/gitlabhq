# frozen_string_literal: true

module Users
  class DropPipelinesForBlockedUserWorker
    include ApplicationWorker

    data_consistency :delayed
    defer_on_database_health_signal :gitlab_ci, [:p_ci_pipelines, :ci_pipeline_schedules], 1.minute

    deduplicate :until_executed
    idempotent!
    feature_category :continuous_integration
    urgency :low

    def perform(user_id)
      user = User.find_by_id(user_id)
      return unless user&.blocked?

      Ci::DropPipelinesAndDisableSchedulesForUserService.new.execute(
        user,
        reason: :user_blocked
      )
    end
  end
end

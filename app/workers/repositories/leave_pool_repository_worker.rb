# frozen_string_literal: true

module Repositories
  class LeavePoolRepositoryWorker
    include ApplicationWorker

    data_consistency :sticky
    idempotent!

    feature_category :gitaly
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:projects], 1.minute

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless project

      project.leave_pool_repository
    end
  end
end

module Milestones
  class ReopenService < Milestones::BaseService
    def execute(milestone)
      if milestone.activate && milestone.is_project_milestone?
        event_service.reopen_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

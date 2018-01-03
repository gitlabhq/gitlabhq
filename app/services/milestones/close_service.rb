module Milestones
  class CloseService < Milestones::BaseService
    def execute(milestone)
      if milestone.close && milestone.project_milestone?
        event_service.close_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

module Milestones
  class CloseService < Milestones::BaseService
    def execute(milestone)
      if milestone.close
        event_service.close_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

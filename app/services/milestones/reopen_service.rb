module Milestones
  class ReopenService < Milestones::BaseService
    def execute(milestone)
      if milestone.reopen
        event_service.reopen_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

# frozen_string_literal: true

module Milestones
  class CloseService < Milestones::BaseService
    def execute(milestone)
      if milestone.close && milestone.project_milestone?
        event_service.close_milestone(milestone, current_user)
        execute_hooks(milestone, 'close')
      end

      milestone
    end
  end
end

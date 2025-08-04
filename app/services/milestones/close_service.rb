# frozen_string_literal: true

module Milestones
  class CloseService < Milestones::BaseService
    def execute(milestone)
      if milestone.close
        event_service.close_milestone(milestone, current_user) if milestone.project_milestone?
        execute_hooks(milestone, 'close')
      end

      milestone
    end
  end
end

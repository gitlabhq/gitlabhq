# frozen_string_literal: true

module Milestones
  class ReopenService < Milestones::BaseService
    def execute(milestone)
      if milestone.activate
        event_service.reopen_milestone(milestone, current_user) if milestone.project_milestone?
        execute_hooks(milestone, 'reopen')
      end

      milestone
    end
  end
end

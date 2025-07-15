# frozen_string_literal: true

module Milestones
  class CreateService < Milestones::BaseService
    def execute
      milestone = parent.milestones.new(params)

      before_create(milestone)

      if milestone.save && milestone.project_milestone?
        event_service.open_milestone(milestone, current_user)
        execute_hooks(milestone, 'create')
      end

      milestone
    end

    private

    def before_create(milestone)
      milestone.check_for_spam(user: current_user, action: :create)
    end
  end
end

module Milestones
  class CreateService < Milestones::BaseService
    def execute
      milestone = parent.milestones.new(params)

      if milestone.save && milestone.project_milestone?
        event_service.open_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

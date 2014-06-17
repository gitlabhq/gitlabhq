module Milestones
  class CreateService < Milestones::BaseService
    def execute
      milestone = project.milestones.new(params)

      if milestone.save
        event_service.open_milestone(milestone, current_user)
      end

      milestone
    end
  end
end

module Milestones
  class UpdateService < Milestones::BaseService
    def execute(milestone)
      state = params.delete('state_event') || params.delete(:state_event)

      case state
      when 'activate'
        Milestones::ReopenService.new(project, current_user, {}).execute(milestone)
      when 'close'
        Milestones::CloseService.new(project, current_user, {}).execute(milestone)
      end

      if params.present?
        milestone.update_attributes(params)
      end

      milestone
    end
  end
end

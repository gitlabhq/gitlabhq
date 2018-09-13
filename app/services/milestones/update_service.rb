# frozen_string_literal: true

module Milestones
  class UpdateService < Milestones::BaseService
<<<<<<< HEAD
    prepend EE::Milestones::UpdateService

=======
>>>>>>> upstream/master
    # rubocop: disable CodeReuse/ActiveRecord
    def execute(milestone)
      state = params[:state_event]

      case state
      when 'activate'
        Milestones::ReopenService.new(parent, current_user, {}).execute(milestone)
      when 'close'
        Milestones::CloseService.new(parent, current_user, {}).execute(milestone)
      end

      if params.present?
        milestone.update(params.except(:state_event))
      end

      milestone
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

# frozen_string_literal: true

module Milestones
  class UpdateService < Milestones::BaseService
    def execute(milestone)
      state = params[:state_event]

      case state
      when 'activate'
        Milestones::ReopenService.new(parent, current_user, {}).execute(milestone)
      when 'close'
        Milestones::CloseService.new(parent, current_user, {}).execute(milestone)
      end

      if params.present?
        milestone.assign_attributes(params.except(:state_event))
      end

      if milestone.changed?
        before_update(milestone)
      end

      milestone.save
      milestone
    end

    private

    def before_update(milestone)
      milestone.check_for_spam(user: current_user, action: :update)
    end
  end
end

Milestones::UpdateService.prepend_mod_with('Milestones::UpdateService')

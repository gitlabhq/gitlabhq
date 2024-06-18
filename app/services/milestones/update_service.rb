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

      milestone.assign_attributes(params.except(:state_event)) if params.present?
      before_update(milestone) if milestone.changed?
      publish_event(milestone) if milestone.save

      milestone
    end

    private

    def before_update(milestone)
      milestone.check_for_spam(user: current_user, action: :update)
    end

    def publish_event(milestone)
      Gitlab::EventStore.publish(
        Milestones::MilestoneUpdatedEvent.new(data: {
          id: milestone.id,
          group_id: milestone.group_id,
          project_id: milestone.project_id,
          updated_attributes: milestone.previous_changes&.keys&.map(&:to_s)
        }.tap(&:compact_blank!))
      )
    end
  end
end

Milestones::UpdateService.prepend_mod_with('Milestones::UpdateService')

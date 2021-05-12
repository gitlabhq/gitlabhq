# frozen_string_literal: true

module Milestones
  class DestroyService < Milestones::BaseService
    def execute(milestone)
      Milestone.transaction do
        update_params = { milestone: nil, skip_milestone_email: true }

        milestone.issues.each do |issue|
          Issues::UpdateService.new(project: parent, current_user: current_user, params: update_params).execute(issue)
        end

        milestone.merge_requests.each do |merge_request|
          MergeRequests::UpdateService.new(project: parent, current_user: current_user, params: update_params).execute(merge_request)
        end

        log_destroy_event_for(milestone)

        milestone.destroy
      end
    end

    def log_destroy_event_for(milestone)
      return if milestone.group_milestone?

      event_service.destroy_milestone(milestone, current_user)

      Event.for_milestone_id(milestone.id).each do |event|
        event.target_id = nil
        event.save
      end
    end
  end
end

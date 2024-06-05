# frozen_string_literal: true

module Milestones
  class DestroyService < Milestones::BaseService
    BATCH_SIZE = 500

    def execute(milestone)
      Milestone.transaction do
        update_issues(milestone)
        update_merge_requests(milestone)

        log_destroy_event_for(milestone) if milestone.destroy
      end

      return unless milestone.destroyed?

      milestone
    end

    private

    def update_issues(milestone)
      batched_issue_ids = []
      milestone.issues.each_batch(of: BATCH_SIZE) do |issues|
        batched_issue_ids << issues.map do |issue|
          Issues::UpdateService.new(
            container: parent,
            current_user: current_user,
            params: update_params
          ).execute(issue)

          issue.id
        end
      end

      publish_events(milestone, batched_issue_ids)
    end

    def publish_events(milestone, batched_issue_ids)
      root_namespace_id = (milestone.group || milestone.project).root_ancestor.id

      milestone.run_after_commit do
        Gitlab::EventStore.publish_group(batched_issue_ids.map do |issue_ids|
          WorkItems::BulkUpdatedEvent.new(data: {
            work_item_ids: issue_ids,
            root_namespace_id: root_namespace_id,
            updated_attributes: %w[milestone_id]
          })
        end)
      end
    end

    def update_merge_requests(milestone)
      milestone.merge_requests.each do |merge_request|
        MergeRequests::UpdateService.new(
          project: merge_request.project,
          current_user: current_user,
          params: update_params
        ).execute(merge_request)
      end
    end

    def update_params
      @update_params ||= { milestone_id: nil, skip_milestone_email: true }
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

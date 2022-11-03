# frozen_string_literal: true

# Milestones::TransferService class
#
# Used for recreating the missing group milestones at project level when
# transferring a project to a new namespace
#
module Milestones
  class TransferService
    attr_reader :current_user, :old_group, :project

    def initialize(current_user, old_group, project)
      @current_user = current_user
      @old_group = old_group
      @project = project
    end

    def execute
      return unless old_group.present?

      Milestone.transaction do
        milestones_to_transfer.find_each do |milestone|
          new_milestone = find_or_create_milestone(milestone)

          update_issues_milestone(milestone, new_milestone)
          update_merge_requests_milestone(milestone.id, new_milestone&.id)

          delete_milestone_counts_caches(milestone)
          delete_milestone_counts_caches(new_milestone)
        end
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def milestones_to_transfer
      Milestone.from_union([group_milestones_applied_to_issues, group_milestones_applied_to_merge_requests])
        .reorder(nil)
        .distinct
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_milestones_applied_to_issues
      Milestone.joins(:issues)
        .where(
          issues: { project_id: project.id },
          group_id: old_group.self_and_ancestors
        )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_milestones_applied_to_merge_requests
      Milestone.joins(:merge_requests)
        .where(
          merge_requests: { target_project_id: project.id },
          group_id: old_group.self_and_ancestors
        )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_or_create_milestone(milestone)
      params = milestone.attributes.slice('title', 'description', 'start_date', 'due_date', 'state')

      FindOrCreateService.new(project, current_user, params).execute
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def update_issues_milestone(old_milestone, new_milestone)
      Issue.where(project: project, milestone_id: old_milestone.id)
        .update_all(milestone_id: new_milestone&.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_merge_requests_milestone(old_milestone_id, new_milestone_id)
      MergeRequest.where(project: project, milestone_id: old_milestone_id)
        .update_all(milestone_id: new_milestone_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def delete_milestone_counts_caches(milestone)
      return unless milestone

      Milestones::IssuesCountService.new(milestone).delete_cache
      Milestones::ClosedIssuesCountService.new(milestone).delete_cache
      Milestones::MergeRequestsCountService.new(milestone).delete_cache
    end
  end
end

# frozen_string_literal: true

module Milestones
  class PromoteService < Milestones::BaseService
    PromoteMilestoneError = Class.new(StandardError)

    def execute(milestone)
      check_project_milestone!(milestone)

      Milestone.transaction do
        group_milestone = clone_project_milestone(milestone)

        move_children_to_group_milestone(group_milestone)

        # Destroy all milestones with same title across projects
        destroy_old_milestones(milestone)

        # Rollback if milestone is not valid
        unless group_milestone.valid?
          raise_error(group_milestone.errors.full_messages.to_sentence)
        end

        group_milestone
      end
    end

    private

    def milestone_ids_for_merge(group_milestone)
      # Pluck need to be used here instead of select so the array of ids
      # is persistent after old milestones gets deleted.
      @milestone_ids_for_merge ||= begin
        search_params = { title: group_milestone.title, project_ids: group_project_ids, state: 'all' }
        milestones = MilestonesFinder.new(search_params).execute
        milestones.pluck_primary_key
      end
    end

    def move_children_to_group_milestone(group_milestone)
      milestone_ids_for_merge(group_milestone).in_groups_of(100, false) do |milestone_ids|
        update_children(group_milestone, milestone_ids)
      end
    end

    def check_project_milestone!(milestone)
      raise_error(s_('PromoteMilestone|Only project milestones can be promoted.')) unless milestone.project_milestone?
    end

    def clone_project_milestone(milestone)
      params = milestone.slice(:title, :description, :start_date, :due_date, :state_event)

      create_service = CreateService.new(group, current_user, params)

      milestone = create_service.execute

      # milestone won't be valid here because of duplicated title
      milestone.save(validate: false)

      milestone
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def update_children(group_milestone, milestone_ids)
      issues = Issue.where(project_id: group_project_ids, milestone_id: milestone_ids)
      merge_requests = MergeRequest.where(source_project_id: group_project_ids, milestone_id: milestone_ids)

      [issues, merge_requests].each do |issuable_collection|
        issuable_collection.update_all(milestone_id: group_milestone.id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def group
      @group ||= parent.group || raise_error(s_('PromoteMilestone|Project does not belong to a group.'))
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_old_milestones(milestone)
      Milestone.where(id: milestone_ids_for_merge(milestone)).destroy_all # rubocop: disable Cop/DestroyAll
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def group_project_ids
      group.projects.select(:id)
    end

    def raise_error(message)
      raise PromoteMilestoneError, s_("PromoteMilestone|Promotion failed - %{message}") % { message: message }
    end
  end
end

Milestones::PromoteService.prepend_mod_with('Milestones::PromoteService')

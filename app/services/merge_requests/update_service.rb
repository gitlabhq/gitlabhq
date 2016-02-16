require_relative 'base_service'
require_relative 'reopen_service'
require_relative 'close_service'

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    def execute(merge_request)
      # We don't allow change of source/target projects and source branch
      # after merge request was created
      params.except!(:source_project_id)
      params.except!(:target_project_id)
      params.except!(:source_branch)

      update(merge_request)
    end

    def handle_changes(merge_request, options = {})
      if have_changes?(merge_request, options)
        task_service.mark_as_done(merge_request, current_user)
      end

      if merge_request.previous_changes.include?('target_branch')
        create_branch_change_note(merge_request, 'target',
                                  merge_request.previous_changes['target_branch'].first,
                                  merge_request.target_branch)
      end

      if merge_request.previous_changes.include?('milestone_id')
        create_milestone_note(merge_request)
      end

      if merge_request.previous_changes.include?('assignee_id')
        create_assignee_note(merge_request)
        notification_service.reassigned_merge_request(merge_request, current_user)
        task_service.reassigned_merge_request(merge_request, current_user)
      end

      if merge_request.previous_changes.include?('target_branch') ||
          merge_request.previous_changes.include?('source_branch')
        merge_request.mark_as_unchecked
      end
    end

    def reopen_service
      MergeRequests::ReopenService
    end

    def close_service
      MergeRequests::CloseService
    end

    private

    def have_changes?(merge_request, options = {})
      valid_attrs = [:title, :description, :assignee_id, :milestone_id, :target_branch]

      attrs_changed = valid_attrs.any? do |attr|
        merge_request.previous_changes.include?(attr.to_s)
      end

      old_labels = options[:old_labels]
      labels_changed = old_labels && merge_request.labels != old_labels

      if attrs_changed || labels_changed
        task_service.mark_as_done(merge_request, current_user)
      end
    end
  end
end

require_relative 'base_service'
require_relative 'reopen_service'
require_relative 'close_service'

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    def execute(merge_request)
      # We dont allow change of source/target projects
      # after merge request was created
      params.except!(:source_project_id)
      params.except!(:target_project_id)

      state = params[:state_event]

      case state
      when 'reopen'
        MergeRequests::ReopenService.new(project, current_user, {}).execute(merge_request)
      when 'close'
        MergeRequests::CloseService.new(project, current_user, {}).execute(merge_request)
      end

      if params.present? && merge_request.update_attributes(params.except(:state_event))
        merge_request.reset_events_cache

        if merge_request.previous_changes.include?('milestone_id')
          create_milestone_note(merge_request)
        end

        if merge_request.previous_changes.include?('assignee_id')
          notification_service.reassigned_merge_request(merge_request, current_user)
          create_assignee_note(merge_request)
        end

        merge_request.notice_added_references(merge_request.project, current_user)
        execute_hooks(merge_request)
      end

      merge_request
    end
  end
end

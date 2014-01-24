module MergeRequests
  class BaseMergeService

    private

    def notification
      NotificationService.new
    end

    def create_merge_event(merge_request)
      Event.create(
        project: merge_request.target_project,
        target_id: merge_request.id,
        target_type: merge_request.class.name,
        action: Event::MERGED,
        author_id: merge_request.author_id_of_changes
      )
    end

    def execute_project_hooks(merge_request)
      if merge_request.project
        merge_request.project.execute_hooks(merge_request.to_hook_data, :merge_request_hooks)
      end
    end
  end
end

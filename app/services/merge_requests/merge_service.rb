module MergeRequests
  # MergeService class
  #
  # Mark existing merge request as merged
  # and execute all hooks and notifications
  # Called when you do merge via command line and push code
  # to target branch
  class MergeService < BaseMergeService
    def execute(merge_request, current_user, commit_message)
      merge_request.author_id_of_changes = current_user.id
      merge_request.merge

      notification.merge_mr(merge_request)
      create_merge_event(merge_request)
      execute_project_hooks(merge_request)

      true
    rescue
      false
    end
  end
end

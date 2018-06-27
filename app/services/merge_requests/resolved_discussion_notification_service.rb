module MergeRequests
  class ResolvedDiscussionNotificationService < MergeRequests::BaseService
    def execute(merge_request)
      return unless merge_request.discussions_resolved?

      SystemNoteService.resolve_all_discussions(merge_request, project, current_user)
      notification_service.async.resolve_all_discussions(merge_request, current_user)
    end
  end
end

module MergeRequests
  class AllDiscussionsResolvedService < MergeRequests::BaseService
    def execute(merge_request)
      return unless merge_request.discussions_resolved?

      SystemNoteService.resolve_all_discussions(merge_request, project, current_user)
      notification_service.resolve_all_discussions(merge_request, current_user)
    end
  end
end

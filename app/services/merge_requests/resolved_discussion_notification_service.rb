# frozen_string_literal: true

module MergeRequests
  class ResolvedDiscussionNotificationService < MergeRequests::BaseService
    def execute(merge_request, send_notifications: true)
      return unless merge_request.discussions_resolved?

      SystemNoteService.resolve_all_discussions(merge_request, project, current_user)
      execute_hooks(merge_request, 'update')

      return unless send_notifications

      notification_service.async.resolve_all_discussions(merge_request, current_user)
    end
  end
end

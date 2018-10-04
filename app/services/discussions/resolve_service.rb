# frozen_string_literal: true

module Discussions
  class ResolveService < Discussions::BaseService
    def execute(one_or_more_discussions)
      Array(one_or_more_discussions).each { |discussion| resolve_discussion(discussion) }
    end

    def resolve_discussion(discussion)
      return unless discussion.can_resolve?(current_user)

      discussion.resolve!(current_user)

      MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(merge_request)
      SystemNoteService.discussion_continued_in_issue(discussion, project, current_user, follow_up_issue) if follow_up_issue
    end

    def merge_request
      params[:merge_request]
    end

    def follow_up_issue
      params[:follow_up_issue]
    end
  end
end

# frozen_string_literal: true

module Discussions
  class ResolveService < Discussions::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(project, user = nil, params = {})
      @discussions = Array.wrap(params.fetch(:one_or_more_discussions))
      @follow_up_issue = params[:follow_up_issue]
      @resolved_count = 0

      raise ArgumentError, 'Discussions must be all for the same noteable' \
        unless noteable_is_same?

      super
    end

    def execute
      discussions.each(&method(:resolve_discussion))
      process_auto_merge
    end

    private

    attr_accessor :discussions, :follow_up_issue

    def noteable_is_same?
      return true unless discussions.size > 1

      # Perform this check without fetching extra records
      discussions.all? do |discussion|
        discussion.noteable_type == first_discussion.noteable_type &&
          discussion.noteable_id == first_discussion.noteable_id
      end
    end

    def resolve_discussion(discussion)
      return unless discussion.can_resolve?(current_user)

      discussion.resolve!(current_user)
      @resolved_count += 1

      if merge_request
        Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
          .track_resolve_thread_action(user: current_user)

        MergeRequests::ResolvedDiscussionNotificationService.new(project: project, current_user: current_user).execute(merge_request)
      end

      resolve_user_todos_for(discussion)
      SystemNoteService.discussion_continued_in_issue(discussion, project, current_user, follow_up_issue) if follow_up_issue
    end

    def resolve_user_todos_for(discussion)
      return unless discussion.for_design?

      TodoService.new.resolve_todos_for_target(discussion, current_user)
    end

    def first_discussion
      @first_discussion ||= discussions.first
    end

    def merge_request
      strong_memoize(:merge_request) do
        first_discussion.noteable if first_discussion.for_merge_request?
      end
    end

    def process_auto_merge
      return unless merge_request
      return unless @resolved_count > 0
      return unless discussions_ready_to_merge?

      AutoMergeProcessWorker.perform_async(merge_request.id)
    end

    def discussions_ready_to_merge?
      merge_request.auto_merge_enabled? && merge_request.mergeable_discussions_state?
    end
  end
end

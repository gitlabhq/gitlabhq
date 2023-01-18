# frozen_string_literal: true

module Discussions
  class UnresolveService < Discussions::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(discussion, user)
      @discussion = discussion
      @user = user

      super
    end

    def execute
      @all_discussions_resolved_before = merge_request ? @discussion.noteable.discussions_resolved? : false

      @discussion.unresolve!

      send_graphql_triggers

      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
        .track_unresolve_thread_action(user: @user)
    end

    private

    def merge_request
      @discussion.noteable if @discussion.for_merge_request?
    end
    strong_memoize_attr :merge_request

    def send_graphql_triggers
      return unless merge_request && @all_discussions_resolved_before

      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end
  end
end

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
      @discussion.unresolve!

      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
        .track_unresolve_thread_action(user: @user)
    end
  end
end

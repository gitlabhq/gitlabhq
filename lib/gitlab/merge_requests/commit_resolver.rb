# frozen_string_literal: true

module Gitlab
  module MergeRequests
    # Resolves a commit_id (sha) to a Commit when it belongs to the merge
    # request's own commits or its recent context commits; nil otherwise.
    class CommitResolver
      def initialize(merge_request, commit_id)
        @merge_request = merge_request
        @commit_id = commit_id.presence
      end

      def resolve
        return unless commit_id
        return unless belongs_to_merge_request?

        merge_request.project.commit(commit_id)
      end

      private

      attr_reader :merge_request, :commit_id

      def belongs_to_merge_request?
        merge_request.commit_exists?(commit_id) ||
          merge_request.recent_context_commits.map(&:id).include?(commit_id)
      end
    end
  end
end

module MergeRequests
  module Conflicts
    class ListService < MergeRequests::Conflicts::BaseService
      delegate :file_for_path, :to_json, to: :conflicts

      def can_be_resolved_by?(user)
        return false unless merge_request.source_project

        access = ::Gitlab::UserAccess.new(user, project: merge_request.source_project)
        access.can_push_to_branch?(merge_request.source_branch)
      end

      def can_be_resolved_in_ui?
        return @conflicts_can_be_resolved_in_ui if defined?(@conflicts_can_be_resolved_in_ui)

        return @conflicts_can_be_resolved_in_ui = false unless merge_request.cannot_be_merged?
        return @conflicts_can_be_resolved_in_ui = false unless merge_request.has_complete_diff_refs?
        return @conflicts_can_be_resolved_in_ui = false if merge_request.branch_missing?

        @conflicts_can_be_resolved_in_ui = conflicts.can_be_resolved_in_ui?
      end

      def conflicts
        @conflicts ||= Gitlab::Conflict::FileCollection.new(merge_request)
      end
    end
  end
end

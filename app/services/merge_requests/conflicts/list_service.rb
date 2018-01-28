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

        begin
          # Try to parse each conflict. If the MR's mergeable status hasn't been
          # updated, ensure that we don't say there are conflicts to resolve
          # when there are no conflict files.
          conflicts.files.each(&:lines)
          @conflicts_can_be_resolved_in_ui = conflicts.files.length > 0
        rescue Gitlab::Git::CommandError, Gitlab::Git::Conflict::Parser::UnresolvableError, Gitlab::Git::Conflict::Resolver::ConflictSideMissing
          @conflicts_can_be_resolved_in_ui = false
        end
      end

      def conflicts
        @conflicts ||= Gitlab::Conflict::FileCollection.new(merge_request)
      end
    end
  end
end

# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class ConflictsResolver < BaseResolver
      type [::Types::MergeRequests::ConflictType], null: true

      calls_gitaly!

      alias_method :merge_request, :object

      def resolve
        return unless merge_request.cannot_be_merged?
        return unless merge_request.has_complete_diff_refs?
        return if merge_request.branch_missing?

        list_service = ::MergeRequests::Conflicts::ListService.new(merge_request, allow_tree_conflicts: true)
        return unless list_service.can_be_resolved_by?(current_user)

        list_service.conflicts.files
      rescue Gitlab::Git::Conflict::Resolver::ConflictSideMissing,
        Gitlab::Git::CommandError
        nil
      end
    end
  end
end

# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class ConflictStatusResolver < BaseResolver
      type ::Types::MergeRequests::ConflictStatusEnum, null: true

      calls_gitaly!

      alias_method :merge_request, :object

      def resolve
        return :no_conflicts if merge_request.can_be_merged?
        return :unchecked unless merge_request.cannot_be_merged?
        return :branch_missing unless merge_request.has_complete_diff_refs? && !merge_request.branch_missing?

        list_service = ::MergeRequests::Conflicts::ListService.new(merge_request, allow_tree_conflicts: true)
        return :no_push_access unless list_service.can_be_resolved_by?(current_user)

        :has_conflicts
      end
    end
  end
end

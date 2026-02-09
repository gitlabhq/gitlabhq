# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckConflictStatusService < CheckBaseService
      set_identifier :conflict
      set_description 'Checks whether the merge request has a conflict'

      def execute
        # rubocop:disable Lint/DuplicateBranch -- Need to check this first
        if merge_request.source_branch_sha != merge_request.merge_request_diff&.head_commit_sha
          checking
        elsif merge_request.can_be_merged?
          success
        elsif merge_request.cannot_be_merged?
          failure
        else
          checking
        end
        # rubocop:enable Lint/DuplicateBranch
      end

      def skip?
        params[:skip_conflict_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end

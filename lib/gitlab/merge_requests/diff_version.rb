# frozen_string_literal: true

module Gitlab
  module MergeRequests
    class DiffVersion
      def initialize(merge_request, params = {})
        @merge_request = merge_request
        @params = params
      end

      def resolve
        return merge_request.merge_head_diff if merge_head_diff?
        return merge_request.merge_request_diff if diff_id.blank?

        merge_request_diff_by_id
      end

      private

      attr_reader :merge_request, :params

      def merge_head_diff?
        merge_request.diffable_merge_ref? && diff_id.blank? && start_sha.blank?
      end

      def merge_request_diff_by_id
        found_diff = merge_request.find_viewable_diff_by_id(diff_id)

        if start_sha.present?
          comparable_diffs = viewable_merge_request_diffs.select { |diff| diff.id < found_diff.id }
          start_version = comparable_diffs.find { |diff| diff.head_commit_sha == start_sha }
          start_version_sha = start_version.head_commit_sha if start_version

          if start_version_sha
            return ::MergeRequests::MergeRequestDiffComparison
              .new(found_diff)
              .compare_with(start_version_sha)
          end
        end

        found_diff
      end

      def viewable_merge_request_diffs
        merge_request.viewable_recent_merge_request_diffs
      end

      def diff_id
        params[:diff_id]
      end

      def start_sha
        params[:start_sha]
      end
    end
  end
end

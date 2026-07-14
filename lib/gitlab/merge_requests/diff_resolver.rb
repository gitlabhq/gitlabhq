# frozen_string_literal: true

module Gitlab
  module MergeRequests
    class DiffResolver
      include Gitlab::Utils::StrongMemoize

      def initialize(merge_request, params = {})
        @merge_request = merge_request
        @params = params
      end

      def resolve
        return merge_request.compare if merge_request.compare
        return commit if commit.present?
        return merge_request.merge_head_diff if merge_head_diff?
        return merge_request.latest_merge_request_diff || merge_request.merge_request_diff if diff_id.blank?

        merge_request_diff_by_id
      end

      def latest?
        return false if merge_request.compare
        return false if commit.present?
        return true if merge_head_diff?

        diff_id.blank? || latest_diff_id?
      end

      private

      attr_reader :merge_request, :params

      def merge_head_diff?
        merge_request.diffable_merge_ref? && start_sha.blank? && (diff_id.blank? || latest_diff_id?)
      end

      def latest_diff_id?
        merge_request.latest_merge_request_diff_id == diff_id.to_i
      end

      def commit
        ::Gitlab::MergeRequests::CommitResolver.new(merge_request, commit_id).resolve
      end
      strong_memoize_attr :commit

      def merge_request_diff_by_id
        # An :empty diff (no changes between source and target) is a real version
        # but is excluded from the viewable scope. Look it up among all diffs so an
        # empty version resolves to itself and renders as an empty diff, instead of
        # raising RecordNotFound (a 404) downstream. A genuinely unknown id still raises.
        found_diff = merge_request.merge_request_diffs.find(diff_id)

        if start_sha.present?
          comparable_diffs = viewable_merge_request_diffs.select { |diff| diff.id < found_diff.id }
          start_version = comparable_diffs.find { |diff| diff.head_commit_sha == start_sha }

          if start_version
            return ::MergeRequests::MergeRequestDiffComparison
              .new(found_diff)
              .compare_with(start_version.head_commit_sha)
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

      def commit_id
        params[:commit_id]
      end
    end
  end
end

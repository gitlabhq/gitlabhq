# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class DetailedMergeStatusService
      include ::Gitlab::Utils::StrongMemoize

      def initialize(merge_request:)
        @merge_request = merge_request
      end

      def execute
        return :preparing if preparing?
        return :checking if checking?
        return :unchecked if unchecked?

        if check_results.success?
          # If everything else is mergeable, but CI is not, the frontend expects two potential states to be returned
          # See discussion: gitlab.com/gitlab-org/gitlab/-/merge_requests/96778#note_1093063523
          if check_ci_results.failed?
            ci_check_failed_check
          else
            :mergeable
          end
        else
          # This check can only fail in EE
          if check_results.payload[:unsuccessful_check] == :not_approved &&
              merge_request.temporarily_unapproved?
            return :approvals_syncing
          end

          check_results.payload[:unsuccessful_check]
        end
      end

      private

      attr_reader :merge_request, :checks, :ci_check

      def preparing?
        merge_request.preparing?
      end

      def checking?
        merge_request.cannot_be_merged_rechecking? || merge_request.checking?
      end

      def unchecked?
        merge_request.unchecked?
      end

      def check_results
        strong_memoize(:check_results) do
          merge_request
            .execute_merge_checks(
              MergeRequest.all_mergeability_checks,
              params: { skip_ci_check: true }
            )
        end
      end

      def check_ci_results
        strong_memoize(:check_ci_results) do
          ::MergeRequests::Mergeability::CheckCiStatusService.new(merge_request: merge_request, params: {}).execute
        end
      end

      def ci_check_failed_check
        if merge_request.diff_head_pipeline_considered_in_progress?
          :ci_still_running
        else
          check_ci_results.payload.fetch(:identifier)
        end
      end
    end
  end
end

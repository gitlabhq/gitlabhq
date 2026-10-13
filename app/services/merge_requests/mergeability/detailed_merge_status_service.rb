# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class DetailedMergeStatusService
      include ::Gitlab::Utils::StrongMemoize

      def initialize(merge_request:, precomputed_results: nil)
        @merge_request = merge_request
        @passed_results = precomputed_results
      end

      def execute
        return :preparing if preparing?
        return :checking if checking?
        return :unchecked if unchecked?
        return ci_status unless unsuccessful_check

        return :approvals_syncing if unsuccessful_check.identifier == :not_approved &&
          merge_request.temporarily_unapproved?

        unsuccessful_check.identifier
      end

      private

      attr_reader :merge_request, :passed_results

      def preparing?
        merge_request.preparing?
      end

      def checking?
        merge_request.cannot_be_merged_rechecking? || merge_request.checking?
      end

      def unchecked?
        merge_request.unchecked?
      end

      # Passed by GraphQL when it resolves `mergeabilityChecks` alongside this
      # field, so the suite is not executed twice in the same request.
      def precomputed_results
        return unless Feature.enabled?(:reuse_mergeability_check_results, merge_request.project,
          type: :gitlab_com_derisk)

        passed_results
      end
      strong_memoize_attr :precomputed_results

      def unsuccessful_check
        results =
          if precomputed_results
            precomputed_results.reject { |result| skipped_identifiers.include?(result.identifier) }
          else
            check_results.payload[:results]
          end

        results.find(&:unsuccessful?)
      end
      strong_memoize_attr :unsuccessful_check

      # A full run is executed without `check_params`, so the checks this
      # service skips are still present in `precomputed_results` and have to be
      # filtered out here to match the fail-fast run.
      def skipped_identifiers
        MergeRequest.all_mergeability_checks.filter_map do |check_class|
          check_class.identifier if check_class.new(merge_request: merge_request, params: check_params).skip?
        end
      end
      strong_memoize_attr :skipped_identifiers

      def check_results
        merge_request.execute_merge_checks(
          MergeRequest.all_mergeability_checks,
          params: check_params
        )
      end
      strong_memoize_attr :check_results

      def check_params
        { skip_ci_check: true }
      end

      def ci_check_result
        precomputed_ci_check_result ||
          ::MergeRequests::Mergeability::CheckCiStatusService.new(merge_request: merge_request, params: {}).execute
      end
      strong_memoize_attr :ci_check_result

      # The CI check is prepended in JH, so an override could leave it out of a
      # full run; run it directly then instead of failing on a missing result.
      def precomputed_ci_check_result
        precomputed_results&.find { |result| result.identifier == ci_check_identifier }
      end

      def ci_check_identifier
        ::MergeRequests::Mergeability::CheckCiStatusService.identifier
      end

      # If everything else is mergeable, but CI is not, the frontend expects two potential states to be returned
      # See discussion: gitlab.com/gitlab-org/gitlab/-/merge_requests/96778#note_1093063523
      def ci_status
        return :mergeable unless ci_check_result.unsuccessful?
        return :ci_still_running if merge_request.diff_head_pipeline_considered_in_progress?

        ci_check_result.identifier
      end
    end
  end
end

# rubocop: disable Cop/InjectEnterpriseEditionModule -- Length of line too long
MergeRequests::Mergeability::DetailedMergeStatusService
  .prepend_mod_with('MergeRequests::Mergeability::DetailedMergeStatusService')
# rubocop: enable Cop/InjectEnterpriseEditionModule

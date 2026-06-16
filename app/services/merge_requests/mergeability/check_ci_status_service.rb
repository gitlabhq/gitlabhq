# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckCiStatusService < CheckBaseService
      include Gitlab::Utils::StrongMemoize

      set_identifier :ci_must_pass
      set_description 'Checks whether CI has passed'

      def execute
        return inactive unless merge_request.auto_merge_enabled? ||
          merge_request.only_allow_merge_if_pipeline_succeeds?

        if mergeable_ci_state?
          success
        elsif pipeline_pending?
          log_diagnostic('checking')
          checking
        else
          log_diagnostic('failure')
          failure
        end
      end

      def skip?
        params[:skip_ci_check].present?
      end

      def cacheable?
        false
      end

      private

      def mergeable_ci_state?
        return true unless pipeline_must_succeed?
        return false unless head_pipeline
        return false if merge_request.pipeline_creating?
        return true if can_skip_diff_head_pipeline?

        head_pipeline.success?
      end

      def pipeline_pending?
        merge_request.pipeline_creating? || head_pipeline&.active?
      end

      def pipeline_must_succeed?
        merge_request.only_allow_merge_if_pipeline_succeeds? ||
          (auto_merge_strategy_requires_ci? && merge_request.has_ci_enabled?)
      end

      def auto_merge_strategy_requires_ci?
        strategies = [
          ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
          ::AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_CHECKS_PASS
        ]

        strategies.include?(merge_request.auto_merge_strategy)
      end

      def can_skip_diff_head_pipeline?
        merge_request.project.allow_merge_on_skipped_pipeline?(inherit_group_setting: true) &&
          head_pipeline.skipped?
      end

      def head_pipeline
        merge_request.diff_head_pipeline
      end
      strong_memoize_attr :head_pipeline

      # Diagnostic logging for https://gitlab.com/gitlab-org/gitlab/-/issues/596177.
      # When CI reports a non-success state for an auto-merge MR, capture enough
      # state to tell a stale `pipeline_creating?` Redis flag apart from a stale
      # or mismatched head pipeline. Behind the `auto_merge_diagnostic_logging`
      # ops flag, enabled per-project while we investigate stuck auto-merge MRs.
      def log_diagnostic(ci_check_status)
        return unless merge_request.auto_merge_enabled?
        return unless Feature.enabled?(:auto_merge_diagnostic_logging, merge_request.project)

        creation_requests = ::Ci::PipelineCreation::Requests.for_merge_request(merge_request)

        Gitlab::AppJsonLogger.info(
          message: 'auto_merge_ci_diagnostic',
          merge_request_id: merge_request.id,
          project_id: merge_request.project_id,
          auto_merge_strategy: merge_request.auto_merge_strategy,
          ci_check_status: ci_check_status,
          merge_status: merge_request.merge_status,
          pipeline_creating: merge_request.pipeline_creating?,
          pipeline_creation_requests: creation_requests,
          head_pipeline_id: merge_request.head_pipeline_id,
          diff_head_pipeline_id: head_pipeline&.id,
          head_pipeline_status: head_pipeline&.status,
          diff_head_sha: merge_request.diff_head_sha
        )
      end
    end
  end
end

# JH required
::MergeRequests::Mergeability::CheckCiStatusService.prepend_mod

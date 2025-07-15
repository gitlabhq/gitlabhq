# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckCiStatusService < CheckBaseService
      include Gitlab::Utils::StrongMemoize

      identifier :ci_must_pass
      description 'Checks whether CI has passed'

      def execute
        return inactive unless merge_request.auto_merge_enabled? ||
          merge_request.only_allow_merge_if_pipeline_succeeds?

        if mergeable_ci_state?
          success
        elsif pipeline_pending?
          checking
        else
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
          (merge_request.auto_merge_strategy == ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS &&
           merge_request.has_ci_enabled?)
      end

      def can_skip_diff_head_pipeline?
        merge_request.project.allow_merge_on_skipped_pipeline?(inherit_group_setting: true) &&
          head_pipeline.skipped?
      end

      def head_pipeline
        merge_request.diff_head_pipeline
      end
      strong_memoize_attr :head_pipeline
    end
  end
end

# JH required
::MergeRequests::Mergeability::CheckCiStatusService.prepend_mod

# frozen_string_literal: true

module RapidDiffs
  class DiffCompareVersionsEntity < Grape::Entity
    include Gitlab::Utils::StrongMemoize

    expose :source_versions do |merge_request|
      ::RapidDiffs::DiffSourceVersionEntity.represent(
        viewable_recent_merge_request_diffs(merge_request),
        merge_request: merge_request,
        merge_request_diffs: viewable_recent_merge_request_diffs(merge_request),
        diff_id: options[:diff_id],
        start_sha: options[:start_sha]
      )
    end

    expose :target_versions do |merge_request|
      ::RapidDiffs::DiffTargetVersionEntity.represent(
        viewable_target_versions(merge_request),
        merge_request: merge_request,
        merge_request_diffs: viewable_recent_merge_request_diffs(merge_request),
        diff_id: options[:diff_id],
        start_sha: options[:start_sha]
      )
    end

    private

    def viewable_target_versions(merge_request)
      return viewable_recent_merge_request_diffs(merge_request) unless merge_request.diffable_merge_ref?

      # We drop the latest diff from the list of versions as we don't need to include
      # it in the list if HEAD diff is diffable.
      viewable_versions = viewable_recent_merge_request_diffs(merge_request).drop(1)

      [merge_request.merge_head_diff] + viewable_versions
    end

    def viewable_recent_merge_request_diffs(merge_request)
      strong_memoize_with(:viewable_recent_merge_request_diffs, merge_request.id) do
        merge_request.viewable_recent_merge_request_diffs
      end
    end
  end
end

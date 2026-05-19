# frozen_string_literal: true

module RapidDiffs
  class DiffCompareVersionsEntity < Grape::Entity
    include Gitlab::Utils::StrongMemoize
    include Gitlab::Routing

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

    expose :commit, if: ->(_, opts) { opts[:commit_id].present? } do |merge_request|
      next unless merge_request.commit_exists?(options[:commit_id])

      commit = merge_request.project.commit(options[:commit_id])
      next unless commit

      next_commit_id, prev_commit_id = *commit_neighbors(merge_request, commit.id)

      ::RapidDiffs::CommitEntity.represent(
        commit,
        type: :full,
        request: merge_request,
        prev_commit_id: prev_commit_id,
        next_commit_id: next_commit_id
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

    def commit_ids(merge_request)
      strong_memoize_with(:commit_ids, merge_request.id) do
        latest_diff = merge_request.latest_merge_request_diff
        next [] unless latest_diff

        latest_diff.commit_shas
      end
    end

    def commit_neighbors(merge_request, commit_id)
      ids = commit_ids(merge_request)
      index = ids.index(commit_id)

      return [] unless index

      [(index > 0 ? ids[index - 1] : nil), ids[index + 1]]
    end
  end
end

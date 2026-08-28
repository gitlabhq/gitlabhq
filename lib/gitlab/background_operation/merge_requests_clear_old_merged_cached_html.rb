# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    # Clears the rendered-Markdown cache columns (`title_html`, `description_html`,
    # `cached_markdown_version`) on merge requests merged more than `MERGED_CUTOFF`
    # ago, to reclaim disk space.
    #
    # Unlike the operation that clears stale caches, this one clears caches that are
    # perfectly current. The point is not correctness but the low odds that anyone
    # views one of these merge requests again. The cache is self-healing: the next
    # read re-renders both HTML fields and writes back the current version, so the
    # cost of being wrong is one render, not incorrect data.
    #
    # `merged_at` is not a column on `merge_requests`; it lives on
    # `merge_request_metrics`, so the sub-batch joins that table. The join is 1:1,
    # backed by a unique index on `merge_request_metrics.merge_request_id`, and the
    # filter is served by `index_merge_request_metrics_on_merge_request_id_and_merged_at`,
    # a partial index on `(merge_request_id, merged_at) WHERE merged_at IS NOT NULL`.
    #
    # Both filters stay out of `scope_to` so that batching iterates `merge_requests`
    # on its primary key alone. A scoped boundary query would have to carry the join
    # and the unindexed `cached_markdown_version` predicate, and in the stretch past
    # the last eligible row it has no bound to stop at, so it walks to the end of a
    # very large table looking for a match that does not exist.
    #
    # The INNER JOIN skips merge requests with no metrics row, and a NULL `merged_at`
    # (never merged, or a backfill gap) is skipped because `NULL < cutoff` is NULL.
    # Both are deliberately conservative: skipping a row costs nothing, clearing one
    # that should not be cleared costs a render.
    #
    # The version condition is the mirror image of the one in
    # `MergeRequestsClearStaleCachedHtml`, which clears everything strictly below
    # `cached_markdown_version_for_bulk_clear`. Together the two operations partition
    # the table. It also makes repeated runs converge, since clearing sets the version
    # to `NULL` and `NULL >= target` is `NULL`.
    #
    # The relation `each_sub_batch` yields is bounded by a `LIMIT`, not by an upper
    # `id`, so the filters must not be chained onto it directly: that pushes them
    # inside the `LIMIT` and lets a sub-batch scan forward past its own window. The
    # window is bound first with `where(id: sub_batch.select(:id))` instead.
    #
    # `reset_cursor!` is needed because the filter is time-dependent: merge requests
    # keep crossing the cutoff, so each pass starts again from the lowest id rather
    # than resuming where the last one stopped.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/608121.
    class MergeRequestsClearOldMergedCachedHtml < BaseOperationWorker
      MERGED_CUTOFF = 3.years

      METRICS_JOIN = <<~SQL.squish
        INNER JOIN merge_request_metrics
        ON merge_request_metrics.merge_request_id = merge_requests.id
      SQL

      operation_name :update_all
      feature_category :code_review_workflow
      cursor :id

      reset_cursor!

      def perform
        merged_before = MERGED_CUTOFF.ago
        target_version = ::Gitlab::MarkdownCache.cached_markdown_version_for_bulk_clear

        each_sub_batch do |sub_batch|
          # rubocop:disable CodeReuse/ActiveRecord -- Bulk clear on the batch relation
          # rubocop:disable Rails/WhereRange -- Explicit operators read clearer than beginless/endless ranges
          sub_batch.klass
            .where(id: sub_batch.select(:id))
            .joins(METRICS_JOIN)
            .where('merge_request_metrics.merged_at < ?', merged_before)
            .where('merge_requests.cached_markdown_version >= ?', target_version)
            .update_all(title_html: nil, description_html: nil, cached_markdown_version: nil)
          # rubocop:enable CodeReuse/ActiveRecord
          # rubocop:enable Rails/WhereRange
        end
      end
    end
  end
end

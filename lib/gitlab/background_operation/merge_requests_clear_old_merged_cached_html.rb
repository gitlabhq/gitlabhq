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
    # Batching runs over `merge_requests` with `cursor :id`, and `scope_to` joins
    # `merge_request_metrics` and filters on `merged_at`. `merged_at` is not a
    # column on `merge_requests`, so the join is unavoidable. Putting it in
    # `scope_to` rather than inside the sub-batch means the filter also applies to
    # the batch boundary queries, so iteration skips merge requests that cannot
    # match instead of visiting every row in the table.
    #
    # The join is what makes the filter index-backed. It places `merge_request_id`
    # under an equality predicate, so
    # `index_merge_request_metrics_on_merge_request_id_and_merged_at`, a partial
    # index on `(merge_request_id, merged_at) WHERE merged_at IS NOT NULL`, serves
    # the probe as an index-only scan, with `merged_at` as an index condition rather
    # than a heap filter.
    #
    # The cursor must be the batched table's own primary key. A non-primary-key
    # cursor gets the primary key appended as a keyset tie breaker, and the
    # resulting two-column keyset takes a union path the dynamic models used for
    # batching cannot follow, because `from_union` is not defined on
    # `ApplicationRecord`.
    #
    # Merge requests with no `merge_request_metrics` row, and rows whose `merged_at`
    # is `NULL`, drop out through the `INNER JOIN` and the index's partial
    # predicate. Both are deliberately conservative: skipping a row costs nothing,
    # clearing one that should not be cleared costs a render.
    #
    # The `cached_markdown_version` filter stays out of `scope_to` because it is not
    # indexed. It is applied after the window is bound with `where(id:
    # sub_batch.select(:id))`, and that re-binding is load-bearing rather than
    # defensive: the filter targets the same table as the batched relation, so
    # chaining it onto the yielded relation would push it inside that relation's
    # `LIMIT`. Measured yields of a few percent mean a chained filter could not fill
    # a sub-batch from inside its own window, so every sub-batch would scan to the
    # end of its job's range.
    #
    # That version condition is the mirror image of the one in
    # `MergeRequestsClearStaleCachedHtml`, which clears everything strictly below
    # `cached_markdown_version_for_bulk_clear`. Together the two operations
    # partition the table. It also makes repeated runs converge, since clearing sets
    # the version to `NULL` and `NULL >= target` is `NULL`.
    #
    # `reset_cursor!` is needed because the filter is time-dependent: merge requests
    # keep crossing the cutoff, so each pass starts again from the lowest id rather
    # than resuming where the last one stopped.
    #
    # A pass ends by walking from the last eligible id to the highest id to
    # establish that nothing remains. If that becomes expensive, `max_cursor` can be
    # pinned from the schedule entry.
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

      # rubocop:disable CodeReuse/ActiveRecord, Rails/WhereRange -- Relation filter, explicit operator over a range
      scope_to ->(relation) do
        relation.joins(METRICS_JOIN).where('merge_request_metrics.merged_at < ?', MERGED_CUTOFF.ago)
      end
      # rubocop:enable CodeReuse/ActiveRecord, Rails/WhereRange

      reset_cursor!

      def perform
        target_version = ::Gitlab::MarkdownCache.cached_markdown_version_for_bulk_clear

        each_sub_batch do |sub_batch|
          # rubocop:disable CodeReuse/ActiveRecord -- Bulk clear on the batch relation
          # rubocop:disable Rails/WhereRange -- Explicit operators read clearer than beginless/endless ranges
          sub_batch.klass
            .where(id: sub_batch.select(:id))
            .where('cached_markdown_version >= ?', target_version)
            .update_all(title_html: nil, description_html: nil, cached_markdown_version: nil)
          # rubocop:enable CodeReuse/ActiveRecord
          # rubocop:enable Rails/WhereRange
        end
      end
    end
  end
end

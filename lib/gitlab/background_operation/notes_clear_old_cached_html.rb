# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    # Clears the rendered-Markdown cache columns (`note_html`,
    # `cached_markdown_version`) on notes untouched for more than
    # `UPDATED_CUTOFF`, to reclaim disk space.
    #
    # Unlike the operation that clears stale caches, this one clears caches that are
    # perfectly current. The point is not correctness but the low odds that anyone
    # views one of these notes again. The cache is self-healing: the next read
    # re-renders `note_html` and writes back the current version, so the cost of
    # being wrong is one render, not incorrect data.
    #
    # `updated_at` rather than `created_at` marks a note as old, because it tracks
    # the last real edit and so is the closer proxy for inactivity. Regenerating the
    # cache does not move it: `MarkdownCache` writes back through `update_columns`,
    # which skips timestamp bumping. Since `updated_at >= created_at`, this selects a
    # subset of what a `created_at` cutoff would, which is the conservative direction.
    #
    # Neither column records when the HTML was last rendered, so a note read often
    # enough can be cleared and re-rendered repeatedly. That is the tradeoff accepted
    # in https://gitlab.com/gitlab-org/gitlab/-/issues/602028 when the index backing a
    # dedicated timestamp column was not approved. The rows cleared per run are the
    # signal to watch: a count that stays high across runs means we are paying for
    # renders rather than reclaiming space, and the fix then is a separate tracking
    # table rather than a column on `notes`.
    #
    # The criteria stay table-wide rather than per `noteable_type`, so every kind of
    # note ages out on the same rule.
    #
    # Both filters stay out of `scope_to` so that batching iterates `notes` on its
    # primary key alone. A scoped boundary query would have to carry the unindexed
    # `updated_at` and `cached_markdown_version` predicates, and in the stretch past
    # the last eligible row it has no bound to stop at, so it walks to the end of a
    # very large table looking for a match that does not exist.
    #
    # The version condition is the mirror image of the one in
    # `NotesClearStaleCachedHtml`, which clears everything strictly below
    # `cached_markdown_version_for_bulk_clear`. Together the two operations partition
    # the table. It also makes repeated runs converge, since clearing sets the version
    # to `NULL` and `NULL >= target` is `NULL`.
    #
    # The relation `each_sub_batch` yields is bounded by a `LIMIT`, not by an upper
    # `id`, so the filters must not be chained onto it directly: that pushes them
    # inside the `LIMIT` and lets a sub-batch scan forward past its own window. The
    # window is bound first with `where(id: sub_batch.select(:id))` instead.
    #
    # `reset_cursor!` is needed because the filter is time-dependent: notes keep
    # crossing the cutoff, so each pass starts again from the lowest id rather than
    # resuming where the last one stopped.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/628174.
    class NotesClearOldCachedHtml < BaseOperationWorker
      UPDATED_CUTOFF = 3.years

      operation_name :update_all
      feature_category :code_review_workflow
      cursor :id

      reset_cursor!

      def perform
        updated_before = UPDATED_CUTOFF.ago
        target_version = ::Gitlab::MarkdownCache.cached_markdown_version_for_bulk_clear

        each_sub_batch do |sub_batch|
          # rubocop:disable CodeReuse/ActiveRecord -- Bulk clear on the batch relation
          # rubocop:disable Rails/WhereRange -- Explicit operators read clearer than beginless/endless ranges
          sub_batch.klass
            .where(id: sub_batch.select(:id))
            .where('updated_at < ?', updated_before)
            .where('cached_markdown_version >= ?', target_version)
            .update_all(note_html: nil, cached_markdown_version: nil)
          # rubocop:enable CodeReuse/ActiveRecord
          # rubocop:enable Rails/WhereRange
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    # Clears the rendered-Markdown cache (`title_html`, `description_html` and
    # `cached_markdown_version`) on merge requests whose `cached_markdown_version`
    # is below the version we currently treat as current.
    #
    # A row on a stale `cached_markdown_version` is already treated the same as a
    # row with a NULL cache: the next read re-renders both HTML fields and writes
    # back the latest version. Clearing it up front therefore imposes no extra
    # rendering load (those rows would re-render and re-write on access anyway)
    # while reclaiming the wasted `*_html` bytes.
    #
    # The bound comes from `MarkdownCache.cached_markdown_version_for_bulk_clear`,
    # which resolves to the previous version during a phased
    # `CACHE_COMMONMARK_VERSION` rollout and to the write version in steady state.
    #
    # Rows already at or above the bound, and rows already NULL (NULL < bound is
    # NULL/false), are skipped, so a repeated run only writes rows that still
    # carry stale HTML.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/607937.
    class MergeRequestsClearStaleCachedHtml < BaseOperationWorker
      operation_name :update_all
      feature_category :code_review_workflow
      cursor :id

      # Staleness isn't monotonic in id: a CACHE_COMMONMARK_VERSION bump makes rows across the whole
      # table stale at once. Resuming from the previous run's cursor would skip those permanently, so
      # every run rescans from the minimum id; the version filter keeps repeat passes cheap.
      reset_cursor!

      def perform
        target_version = ::Gitlab::MarkdownCache.cached_markdown_version_for_bulk_clear

        each_sub_batch do |sub_batch|
          # rubocop:disable CodeReuse/ActiveRecord, Rails/WhereRange -- Bulk clear on the batch relation
          # The sub-batch is bounded by a LIMIT, not by an upper cursor, so the version
          # filter has to sit outside it. Chaining it on would push it inside the LIMIT,
          # making each sub-batch scan forward past its own window looking for matches.
          sub_batch.klass.where(id: sub_batch.select(:id))
            .where('cached_markdown_version < ?', target_version)
            .update_all(title_html: nil, description_html: nil, cached_markdown_version: nil)
          # rubocop:enable CodeReuse/ActiveRecord, Rails/WhereRange
        end
      end
    end
  end
end

# frozen_string_literal: true

class RemoveIndexMrMetricsOnProjectMergedAtNotDeployed < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_metrics
  INDEX_NAME = :index_mr_metrics_on_project_merged_at_not_deployed

  # The index was prepared async (20260910120000) and built on GitLab.com, but
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256809 made the query
  # use the existing index_mr_metrics_on_target_project_id_merged_at_nulls_last,
  # so the sync follow-up (628640) was dropped and this index is unused.
  def up
    # Cancel any pending async build (self-managed may not have built it yet).
    unprepare_async_index_by_name TABLE_NAME, INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    # No-op: the index only exists on GitLab.com and was never in structure.sql,
    # so there is nothing to recreate on rollback.
  end
end

# frozen_string_literal: true

class PrepareAsyncIndexMrMetricsOnProjectMergedAtNotDeployed < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_metrics
  INDEX_NAME = :index_mr_metrics_on_project_merged_at_not_deployed
  COLUMNS = %i[target_project_id merged_at]

  def up
    # TODO: Follow-up to create index synchronously: https://gitlab.com/gitlab-org/gitlab/-/issues/628635
    # rubocop:disable Migration/PreventIndexCreation -- partial index stays small; the sync follow-up drops the unused index_merge_request_metrics_on_first_deployed_to_production_at to keep the index count flat
    prepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME, where: 'first_deployed_to_production_at IS NULL'
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index_by_name TABLE_NAME, INDEX_NAME
  end
end

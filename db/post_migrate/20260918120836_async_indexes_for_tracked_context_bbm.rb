# frozen_string_literal: true

class AsyncIndexesForTrackedContextBbm < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  INDEX_VULN_OCCURRENCES = 'tmp_idx_vuln_occurrences_on_project_id_where_context_null'
  INDEX_VULN_READS = 'tmp_idx_vuln_reads_on_project_id_where_context_null'
  INDEX_VULN_STATS = 'tmp_idx_vuln_stats_on_project_id_where_context_null'
  INDEX_VULN_HIST_STATS = 'tmp_idx_vuln_hist_stats_on_project_id_where_context_null'

  WHERE_CLAUSE = 'security_project_tracked_context_id IS NULL'

  # rubocop:disable Migration/PreventIndexCreation -- tmp indexes for BBM https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210728
  def up
    prepare_async_index :vulnerability_occurrences, :project_id,
      where: WHERE_CLAUSE,
      name: INDEX_VULN_OCCURRENCES

    prepare_async_index :vulnerability_reads, :project_id,
      where: WHERE_CLAUSE,
      name: INDEX_VULN_READS

    prepare_async_index :vulnerability_statistics, :project_id,
      where: WHERE_CLAUSE,
      name: INDEX_VULN_STATS

    prepare_async_index :vulnerability_historical_statistics, :project_id,
      where: WHERE_CLAUSE,
      name: INDEX_VULN_HIST_STATS
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :vulnerability_occurrences, :project_id, name: INDEX_VULN_OCCURRENCES
    unprepare_async_index :vulnerability_reads, :project_id, name: INDEX_VULN_READS
    unprepare_async_index :vulnerability_statistics, :project_id, name: INDEX_VULN_STATS
    unprepare_async_index :vulnerability_historical_statistics, :project_id, name: INDEX_VULN_HIST_STATS
  end
end

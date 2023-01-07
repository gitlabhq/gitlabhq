# frozen_string_literal: true

class ReindexVulnReadsOnDefaultBranchWithCommonQuery < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vuln_reads_common_query_on_resolved_on_default_branch'

  COLUMNS = %i[project_id state report_type vulnerability_id]

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :vulnerability_reads,
      COLUMNS,
      name: INDEX_NAME,
      where: 'resolved_on_default_branch IS TRUE',
      order: { vulnerability_id: :desc }
    )
  end

  def down
    remove_concurrent_index_by_name(
      :vulnerability_reads,
      INDEX_NAME
    )
  end
end

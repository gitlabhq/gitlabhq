# frozen_string_literal: true

class DropIndexForOwaspTop10GroupLevelReports < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = 'index_for_owasp_top_10_group_level_reports'

  def up
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_reads, [:owasp_top_10, :state, :report_type,
      :severity, :traversal_ids, :vulnerability_id, :resolved_on_default_branch],
      where: 'archived = false',
      name: INDEX_NAME
  end
end

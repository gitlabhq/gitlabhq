# frozen_string_literal: true

class AddIndexOwaspTop10ForGroupLevelReports < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = 'index_for_owasp_top_10_group_level_reports'

  # -- Legacy migration
  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :vulnerability_reads, [:owasp_top_10, :state, :report_type,
      # rubocop:enable Migration/PreventIndexCreation
      :severity, :traversal_ids, :vulnerability_id, :resolved_on_default_branch],
      where: 'archived = false',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end

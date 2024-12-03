# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRevisedIdxOwaspTop10ForGroupLevelReports < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'revised_idx_for_owasp_top_10_group_level_reports'

  # -- Legacy migration
  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :vulnerability_reads, [:owasp_top_10, :state, :report_type, :resolved_on_default_branch,
      # rubocop:enable Migration/PreventIndexCreation
      :severity, :traversal_ids, :vulnerability_id],
      where: 'archived = false',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end

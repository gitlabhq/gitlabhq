# frozen_string_literal: true

class AddTmpIndexVulnReadsOnProjectSptcId < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_vuln_reads_on_project_id_sec_prj_trck_cnxt_id_id'
  COLUMNS = %i[project_id security_project_tracked_context_id id].freeze

  # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/609
  def up
    add_concurrent_index :vulnerability_reads, COLUMNS, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end

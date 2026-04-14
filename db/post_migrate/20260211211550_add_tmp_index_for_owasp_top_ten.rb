# frozen_string_literal: true

class AddTmpIndexForOwaspTopTen < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  INDEX_NAME = 'tmp_index_vuln_reads_on_id_where_owasp_2021'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- tmp index for BBM (https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/597)
    # Temporary index to be removed in a future milestone https://gitlab.com/gitlab-org/gitlab/-/work_items/593414
    add_concurrent_index(
      :vulnerability_reads,
      :id,
      where: 'owasp_top_10 IN (11, 12, 13, 14, 15, 16, 17, 18, 19, 20)',
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(:vulnerability_reads, INDEX_NAME)
  end
end

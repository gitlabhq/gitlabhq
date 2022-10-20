# frozen_string_literal: true

class AddIndexResolvedOnDefaultBranchToVulnerabilitiesRead < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_vuln_reads_on_resolved_on_default_branch'
  COLUMNS = %i[project_id state id]

  def up
    add_concurrent_index :vulnerability_reads, COLUMNS,
                         where: 'resolved_on_default_branch IS TRUE',
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end

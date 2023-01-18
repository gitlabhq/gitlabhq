# frozen_string_literal: true

class DropVulnReadsOnDefaultBranchIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vuln_reads_on_resolved_on_default_branch'

  COLUMNS = %i[project_id state id]

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vulnerability_reads, name: INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_reads, COLUMNS,
                         where: 'resolved_on_default_branch IS TRUE',
                         name: INDEX_NAME
  end
end

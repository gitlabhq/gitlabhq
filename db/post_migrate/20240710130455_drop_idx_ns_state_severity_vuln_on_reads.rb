# frozen_string_literal: true

class DropIdxNsStateSeverityVulnOnReads < Gitlab::Database::Migration[2.2]
  TABLE_NAME = :vulnerability_reads
  INDEX = 'index_vuln_reads_on_namespace_id_state_severity_and_vuln_id'

  milestone '17.2'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      "namespace_id, state, severity, vulnerability_id DESC",
      name: INDEX
    )
  end
end

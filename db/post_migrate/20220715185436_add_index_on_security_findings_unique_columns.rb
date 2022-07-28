# frozen_string_literal: true

class AddIndexOnSecurityFindingsUniqueColumns < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_security_findings_on_unique_columns'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_findings, [:uuid, :scan_id, :partition_number], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end
end

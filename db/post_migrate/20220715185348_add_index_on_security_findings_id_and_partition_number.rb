# frozen_string_literal: true

class AddIndexOnSecurityFindingsIdAndPartitionNumber < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'security_findings_partitioned_pkey'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_findings, [:id, :partition_number], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end
end

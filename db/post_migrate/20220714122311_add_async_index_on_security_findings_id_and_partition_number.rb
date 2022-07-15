# frozen_string_literal: true

class AddAsyncIndexOnSecurityFindingsIdAndPartitionNumber < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'security_findings_partitioned_pkey'

  disable_ddl_transaction!

  def up
    prepare_async_index :security_findings, [:id, :partition_number], unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :security_findings, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddAsyncIndexOnSecurityFindingsUniqueColumns < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_security_findings_on_unique_columns'

  disable_ddl_transaction!

  def up
    prepare_async_index :security_findings, [:uuid, :scan_id, :partition_number], unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :security_findings, INDEX_NAME
  end
end

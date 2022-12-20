# frozen_string_literal: true

class IndexSecurityScansOnCreatedAtAndIdForNonPurgedRecords < Gitlab::Database::Migration[2.0]
  INDEX_NAME = :index_security_scans_for_non_purged_records
  PURGED_STATE = 6

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_scans, %w[created_at id], where: "status != #{PURGED_STATE}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_scans, INDEX_NAME
  end
end

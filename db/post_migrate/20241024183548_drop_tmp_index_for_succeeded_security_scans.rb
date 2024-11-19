# frozen_string_literal: true

class DropTmpIndexForSucceededSecurityScans < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = 'security_scans'
  INDEX_NAME = 'tmp_index_for_succeeded_security_scans'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:id], name: INDEX_NAME, where: 'status = 1'
  end
end

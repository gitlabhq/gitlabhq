# frozen_string_literal: true

class AddTmpIndexForSucceededSecurityScans < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_index_for_succeeded_security_scans'

  disable_ddl_transaction!

  milestone '16.10'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :security_scans, :id, name: INDEX_NAME, where: 'status = 1'
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :security_scans, INDEX_NAME
  end
end

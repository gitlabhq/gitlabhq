# frozen_string_literal: true

class IndexBulkImportsOnTerminatedStatus < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  INDEX_NAME = 'index_bulk_imports_on_terminated_status'

  def up
    add_concurrent_index :bulk_imports, :id,
      name: INDEX_NAME,
      where: "status IN (2, 3, -1, -2)"
  end

  def down
    remove_concurrent_index_by_name :bulk_imports, INDEX_NAME
  end
end

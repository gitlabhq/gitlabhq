# frozen_string_literal: true

class DropIndexNamespacesOnName < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_namespaces_on_name'

  def up
    remove_concurrent_index_by_name :namespaces, INDEX_NAME, if_exists: true
  end

  def down
    # no-op
  end
end

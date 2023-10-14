# frozen_string_literal: true

class DropIndexNamespacesOnUpdatedAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :namespaces
  INDEX_NAME = :index_namespaces_on_updated_at

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    # no-op
    # Since adding the same index will be time consuming,
    # we have to create it asynchronously using 'prepare_async_index' helper.
  end
end

# frozen_string_literal: true

class DropIndexNamespacesOnRunnersToken < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :namespaces
  INDEX_NAME = :index_namespaces_on_runners_token

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :runners_token, unique: true, name: INDEX_NAME
  end
end

# frozen_string_literal: true

class AddIndexToGroupIdColumnOnWebhooksTable < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_group_id_on_webhooks'

  def up
    add_concurrent_index :web_hooks, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :web_hooks, INDEX_NAME
  end
end

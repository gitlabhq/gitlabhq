# frozen_string_literal: true

class AddBotNamespaceIdToUserDetail < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_column :user_details, :bot_namespace_id, :bigint, null: true, if_not_exists: true
    add_concurrent_index :user_details, :bot_namespace_id
  end

  def down
    remove_column :user_details, :bot_namespace_id
  end
end

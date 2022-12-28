# frozen_string_literal: true

class DropIndexOnChatNamesOnUserIdAndIntegrationId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_names_on_user_id_and_integration_id'

  def up
    remove_concurrent_index_by_name(:chat_names, INDEX_NAME)
  end

  def down
    add_concurrent_index(:chat_names, [:user_id, :integration_id], name: INDEX_NAME, unique: true)
  end
end

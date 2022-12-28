# frozen_string_literal: true

class DropIndexOnChatNamesOnIntegrationIdAndTeamIdAndChatId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_names_on_integration_id_and_team_id_and_chat_id'

  def up
    remove_concurrent_index_by_name(:chat_names, INDEX_NAME)
  end

  def down
    add_concurrent_index(:chat_names, [:integration_id, :team_id, :chat_id], name: INDEX_NAME, unique: true)
  end
end

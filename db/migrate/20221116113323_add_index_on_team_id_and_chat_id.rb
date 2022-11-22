# frozen_string_literal: true

class AddIndexOnTeamIdAndChatId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_chat_names_on_team_id_and_chat_id'

  def up
    add_concurrent_index(:chat_names, [:team_id, :chat_id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name :chat_names, INDEX_NAME
  end
end

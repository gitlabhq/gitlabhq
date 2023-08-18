# frozen_string_literal: true

class RemoveChatNamesIntegrationIdColumn < Gitlab::Database::Migration[2.1]
  def up
    remove_column :chat_names, :integration_id
  end

  def down
    add_column :chat_names, :integration_id, :integer, if_not_exists: true
  end
end

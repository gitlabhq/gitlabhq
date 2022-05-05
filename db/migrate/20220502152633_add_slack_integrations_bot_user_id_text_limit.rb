# frozen_string_literal: true

class AddSlackIntegrationsBotUserIdTextLimit < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :slack_integrations, :bot_user_id, 255
  end

  def down
    remove_text_limit :slack_integrations, :bot_user_id
  end
end

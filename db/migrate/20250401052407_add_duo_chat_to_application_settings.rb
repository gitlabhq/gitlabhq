# frozen_string_literal: true

class AddDuoChatToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_duo_chat_is_hash'

  def up
    add_column :application_settings, :duo_chat, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(duo_chat) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_column :application_settings, :duo_chat
  end
end

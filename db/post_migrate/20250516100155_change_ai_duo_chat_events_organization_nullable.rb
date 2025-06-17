# frozen_string_literal: true

class ChangeAiDuoChatEventsOrganizationNullable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_not_null_constraint :ai_duo_chat_events, :organization_id
  end

  def down
    remove_not_null_constraint :ai_duo_chat_events, :organization_id
  end
end

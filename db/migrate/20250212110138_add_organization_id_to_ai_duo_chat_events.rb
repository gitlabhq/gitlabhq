# frozen_string_literal: true

class AddOrganizationIdToAiDuoChatEvents < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :ai_duo_chat_events, :organization_id, :bigint
  end
end

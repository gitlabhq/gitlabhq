# frozen_string_literal: true

class AddEarlyAccessStudioParticipantToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :user_preferences, :early_access_studio_participant, :boolean, default: false, null: false
  end
end

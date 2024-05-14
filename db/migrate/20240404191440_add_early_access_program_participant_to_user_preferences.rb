# frozen_string_literal: true

class AddEarlyAccessProgramParticipantToUserPreferences < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.0'

  def up
    change_table :user_preferences, bulk: true do |t|
      t.boolean :early_access_program_participant, null: false, default: false
      t.boolean :early_access_program_tracking, null: false, default: false
    end
  end

  def down
    remove_columns :user_preferences, :early_access_program_participant, :early_access_program_tracking
  end
end

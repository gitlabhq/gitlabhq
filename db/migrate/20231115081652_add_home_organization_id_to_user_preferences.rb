# frozen_string_literal: true

class AddHomeOrganizationIdToUserPreferences < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    add_column(:user_preferences, :home_organization_id, :bigint, null: true)
  end
end

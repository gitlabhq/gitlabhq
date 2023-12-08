# frozen_string_literal: true

class AddHomeOrganizationIdIndexToUserPreferences < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX = 'index_user_preferences_on_home_organization_id'

  def up
    add_concurrent_index(:user_preferences, :home_organization_id, name: INDEX)
  end

  def down
    remove_concurrent_index_by_name(:user_preferences, name: INDEX)
  end
end

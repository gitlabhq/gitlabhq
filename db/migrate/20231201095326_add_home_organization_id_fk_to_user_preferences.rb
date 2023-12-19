# frozen_string_literal: true

class AddHomeOrganizationIdFkToUserPreferences < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    add_concurrent_foreign_key(:user_preferences, :organizations, column: :home_organization_id, on_delete: :nullify)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :user_preferences, column: :home_organization_id
    end
  end
end

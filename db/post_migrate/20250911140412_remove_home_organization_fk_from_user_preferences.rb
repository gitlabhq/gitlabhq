# frozen_string_literal: true

class RemoveHomeOrganizationFkFromUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :user_preferences, :organizations, column: :home_organization_id
    end
  end

  def down
    add_concurrent_foreign_key :user_preferences, :organizations,
      column: :home_organization_id,
      on_delete: :nullify
  end
end

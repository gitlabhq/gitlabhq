# frozen_string_literal: true

class AddForeignKeysToCustomDashboards < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  def up
    add_concurrent_foreign_key :custom_dashboards, :users, column: :created_by_id, on_delete: :nullify
    add_concurrent_foreign_key :custom_dashboards, :users, column: :updated_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :custom_dashboards, column: :created_by_id
      remove_foreign_key_if_exists :custom_dashboards, column: :updated_by_id
    end
  end
end

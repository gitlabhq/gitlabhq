# frozen_string_literal: true

class AddCustomDashboardVersionsUserFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_custom_dashboard_versions_on_updated_by_id'

  def up
    add_concurrent_foreign_key :custom_dashboard_versions,
      :users,
      column: :updated_by_id,
      on_delete: :nullify

    add_concurrent_index :custom_dashboard_versions,
      :updated_by_id,
      name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :custom_dashboard_versions, column: :updated_by_id
    end
    remove_concurrent_index_by_name :custom_dashboard_versions, INDEX_NAME
  end
end

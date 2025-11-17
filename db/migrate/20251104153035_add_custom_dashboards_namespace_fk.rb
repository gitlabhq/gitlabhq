# frozen_string_literal: true

class AddCustomDashboardsNamespaceFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :custom_dashboards, :namespaces, column: :namespace_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :custom_dashboards, column: :namespace_id
    end
  end
end

# frozen_string_literal: true

class AddOpenStatusFkToWorkItemCustomLifecycles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :work_item_custom_lifecycles, :work_item_custom_statuses,
      column: :default_open_status_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :work_item_custom_lifecycles, column: :default_open_status_id
  end
end

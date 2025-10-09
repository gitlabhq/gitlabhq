# frozen_string_literal: true

class AddOldStatusRoleToWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :work_item_custom_status_mappings, :old_status_role, :integer, limit: 2
  end
end

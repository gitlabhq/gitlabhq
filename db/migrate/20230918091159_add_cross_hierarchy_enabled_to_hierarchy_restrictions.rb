# frozen_string_literal: true

class AddCrossHierarchyEnabledToHierarchyRestrictions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :work_item_hierarchy_restrictions, :cross_hierarchy_enabled, :boolean, default: false, null: false
  end
end

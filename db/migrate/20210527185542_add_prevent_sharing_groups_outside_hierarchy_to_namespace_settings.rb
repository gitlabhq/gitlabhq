# frozen_string_literal: true

class AddPreventSharingGroupsOutsideHierarchyToNamespaceSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :namespace_settings, :prevent_sharing_groups_outside_hierarchy, :boolean, null: false, default: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :prevent_sharing_groups_outside_hierarchy
    end
  end
end

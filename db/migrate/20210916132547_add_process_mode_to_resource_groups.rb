# frozen_string_literal: true

class AddProcessModeToResourceGroups < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  PROCESS_MODE_UNORDERED = 0

  def up
    add_column :ci_resource_groups, :process_mode, :integer, default: PROCESS_MODE_UNORDERED, null: false, limit: 2
  end

  def down
    remove_column :ci_resource_groups, :process_mode
  end
end

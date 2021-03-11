# frozen_string_literal: true

class AddAllowForcePushToProtectedBranches < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :protected_branches, :allow_force_push, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :protected_branches, :allow_force_push
    end
  end
end

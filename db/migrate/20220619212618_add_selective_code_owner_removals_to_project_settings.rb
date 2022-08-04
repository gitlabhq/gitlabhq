# frozen_string_literal: true

class AddSelectiveCodeOwnerRemovalsToProjectSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :selective_code_owner_removals, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class AddForceIncludeAllResourcesToWorkspaces < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :workspaces, :force_include_all_resources, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class ChangeWorkspacesForceIncludeAllResourcesDefault < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    change_column_default(:workspaces, :force_include_all_resources, from: false, to: true)
  end
end

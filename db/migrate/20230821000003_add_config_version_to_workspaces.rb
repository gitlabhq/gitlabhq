# frozen_string_literal: true

class AddConfigVersionToWorkspaces < Gitlab::Database::Migration[2.1]
  def change
    add_column :workspaces, :config_version, :integer, default: 1, null: false
  end
end

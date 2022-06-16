# frozen_string_literal: true

class AddEnabledGitAccessProtocolToNamespaceSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :namespace_settings, :enabled_git_access_protocol, :integer, default: 0, null: false, limit: 2
  end
end

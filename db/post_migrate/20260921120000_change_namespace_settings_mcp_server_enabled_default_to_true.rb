# frozen_string_literal: true

class ChangeNamespaceSettingsMcpServerEnabledDefaultToTrue < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    change_column_default(:namespace_settings, :mcp_server_enabled, from: nil, to: true)
  end
end

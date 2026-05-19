# frozen_string_literal: true

class RenameMcpServerEnabledInApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Rename the 'enabled' key to 'mcp_server_enabled' in the mcp_server_settings JSONB column.
    # The original key was misnamed when the column was introduced.
    execute <<~SQL
      UPDATE application_settings
      SET mcp_server_settings = (mcp_server_settings - 'enabled')
        || jsonb_build_object('mcp_server_enabled', mcp_server_settings->'enabled')
      WHERE mcp_server_settings ? 'enabled'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET mcp_server_settings = (mcp_server_settings - 'mcp_server_enabled')
        || jsonb_build_object('enabled', mcp_server_settings->'mcp_server_enabled')
      WHERE mcp_server_settings ? 'mcp_server_enabled'
    SQL
  end
end

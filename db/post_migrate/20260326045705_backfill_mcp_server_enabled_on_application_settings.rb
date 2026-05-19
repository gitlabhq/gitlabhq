# frozen_string_literal: true

class BackfillMcpServerEnabledOnApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Preserve the previous implicit MCP availability state for existing instances.
    # Although mcp_server_enabled now defaults to true (for new installations),
    # existing instances where MCP was not previously available should remain disabled.
    # MCP was implicitly available only when both duo_features_enabled and
    # instance_level_ai_beta_features_enabled were true.
    execute <<~SQL
      UPDATE application_settings
      SET mcp_server_settings = jsonb_set(mcp_server_settings, '{enabled}', 'false')
      WHERE NOT (duo_features_enabled = TRUE AND instance_level_ai_beta_features_enabled = TRUE)
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET mcp_server_settings = jsonb_set(mcp_server_settings, '{enabled}', 'true')
    SQL
  end
end

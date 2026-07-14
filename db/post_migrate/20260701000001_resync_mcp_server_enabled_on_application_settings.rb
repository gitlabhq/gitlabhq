# frozen_string_literal: true

class ResyncMcpServerEnabledOnApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # mcp_server_settings.mcp_server_enabled was derived from duo_features_enabled AND
    # instance_level_ai_beta_features_enabled at 19.0 backfill time but was never kept in sync
    # afterward. Correct any stale values before mcp_server_enabled becomes the authoritative check.
    execute <<~SQL
      UPDATE application_settings
      SET mcp_server_settings = jsonb_set(
        mcp_server_settings,
        '{mcp_server_enabled}',
        (duo_features_enabled IS TRUE AND instance_level_ai_beta_features_enabled IS TRUE)::text::jsonb
      )
      WHERE (mcp_server_settings->>'mcp_server_enabled')::boolean
        IS DISTINCT FROM (duo_features_enabled IS TRUE AND instance_level_ai_beta_features_enabled IS TRUE)
    SQL
  end

  def down
    # irreversible - prior state is unknown
  end
end

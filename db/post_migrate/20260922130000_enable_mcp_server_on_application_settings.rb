# frozen_string_literal: true

class EnableMcpServerOnApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  AUDIT_SCAN_TIMEOUT = '10min'

  MCP_SERVER_OFF = "(mcp_server_settings->>'mcp_server_enabled')::boolean IS FALSE"

  # One-time catch-up for MCP server GA: the 19.0 and 19.2 migrations wrote mcp_server_enabled
  # from Duo and AI beta settings, which are separate from MCP today. Turn it on unless an admin
  # ever changed it: migrations leave no audit event, so any MCP event means an admin chose.
  # See https://gitlab.com/gitlab-org/gitlab/-/work_items/630175
  def up
    # GitLab.com checks MCP access per group, so the instance value has no effect there.
    return if Gitlab.com?
    return unless mcp_server_off?

    # Separate queries: application_settings and instance_audit_events are in different schemas.
    return if changed_by_admin?

    with_lock_retries do
      execute <<~SQL
        UPDATE application_settings
        SET mcp_server_settings = jsonb_set(mcp_server_settings, '{mcp_server_enabled}', 'true')
        WHERE #{MCP_SERVER_OFF}
      SQL
    end
  end

  def down
    # no-op: the earlier value was not a customer choice, so there is nothing to restore
  end

  private

  def mcp_server_off?
    select_value("SELECT 1 FROM application_settings WHERE #{MCP_SERVER_OFF} LIMIT 1").present?
  end

  # The audit scan has no supporting index, so cap it rather than stall the upgrade.
  # If it times out we can't rule out an admin choice, so we leave MCP off.
  def changed_by_admin?
    transaction do
      execute("SET LOCAL statement_timeout TO '#{AUDIT_SCAN_TIMEOUT}'")

      select_value(<<~'SQL').present?
        SELECT 1
        FROM instance_audit_events
        WHERE created_at >= '2026-03-26' -- the setting did not exist before, so skip older partitions
          AND event_name = 'application_setting_updated'
          AND details ~ E'\n:change: mcp_server_(enabled|settings)\n'
        LIMIT 1
      SQL
    end
  rescue ActiveRecord::QueryCanceled # rubocop:disable Database/RescueQueryCanceled -- the timeout is the intended skip signal
    say "Audit event scan exceeded #{AUDIT_SCAN_TIMEOUT}, leaving the MCP server setting unchanged"
    true
  end
end

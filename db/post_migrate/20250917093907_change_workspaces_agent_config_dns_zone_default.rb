# frozen_string_literal: true

class ChangeWorkspacesAgentConfigDnsZoneDefault < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    change_column_default :workspaces_agent_configs, :dns_zone, from: nil, to: ""
  end

  def down
    change_column_default :workspaces_agent_configs, :dns_zone, from: "", to: nil
  end
end

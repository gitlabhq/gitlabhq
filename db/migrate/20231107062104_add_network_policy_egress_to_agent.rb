# frozen_string_literal: true

class AddNetworkPolicyEgressToAgent < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  NETWORK_POLICY_EGRESS_DEFAULT = [{
    allow: "0.0.0.0/0",
    except: [
      - "10.0.0.0/8",
      - "172.16.0.0/12",
      - "192.168.0.0/16"
    ]
  }]

  def change
    add_column :remote_development_agent_configs,
      :network_policy_egress,
      :jsonb,
      null: false,
      default: NETWORK_POLICY_EGRESS_DEFAULT
  end
end

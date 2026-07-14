# frozen_string_literal: true

class AddDependencyFirewallEnabledToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :namespace_settings, :dependency_firewall_enabled, :boolean, default: false, null: false
  end
end

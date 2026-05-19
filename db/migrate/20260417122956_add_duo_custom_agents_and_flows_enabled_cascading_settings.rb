# frozen_string_literal: true

class AddDuoCustomAgentsAndFlowsEnabledCascadingSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :namespace_settings, :duo_custom_flows_enabled, :boolean, null: true, default: nil
    add_column :namespace_settings, :lock_duo_custom_flows_enabled, :boolean, null: false, default: false
  end

  def down
    remove_column :namespace_settings, :duo_custom_flows_enabled, if_exists: true
    remove_column :namespace_settings, :lock_duo_custom_flows_enabled, if_exists: true
  end
end

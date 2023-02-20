# frozen_string_literal: true

class AddGlobalGroupApproversEnabledToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings,
      :security_policy_global_group_approvers_enabled,
      :boolean,
      default: true,
      null: false
  end
end

# frozen_string_literal: true

class AddSecurityPolicyScheduledScansMaxConcurrencyToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    add_column :application_settings,
      :security_policy_scheduled_scans_max_concurrency,
      :integer,
      default: 100,
      null: false,
      if_not_exists: true
  end

  def down
    remove_column :application_settings, :security_policy_scheduled_scans_max_concurrency
  end
end

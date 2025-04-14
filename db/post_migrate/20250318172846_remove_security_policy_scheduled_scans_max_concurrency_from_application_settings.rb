# frozen_string_literal: true

class RemoveSecurityPolicyScheduledScansMaxConcurrencyFromApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    remove_column :application_settings, :security_policy_scheduled_scans_max_concurrency
  end

  def down
    add_column :application_settings,
      :security_policy_scheduled_scans_max_concurrency,
      :integer,
      default: 10000,
      null: false,
      if_not_exists: true
  end
end

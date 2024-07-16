# frozen_string_literal: true

class UpdateScheduledScansMaxConcurrencyDefaultValue < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def change
    change_column_default :application_settings, :security_policy_scheduled_scans_max_concurrency, from: 100, to: 10000
  end
end

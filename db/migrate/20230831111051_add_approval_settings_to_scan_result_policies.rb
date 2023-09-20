# frozen_string_literal: true

class AddApprovalSettingsToScanResultPolicies < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :scan_result_policies, :project_approval_settings, :jsonb, default: {}, null: false
    add_column :scan_result_policies, :commits, :smallint
  end
end

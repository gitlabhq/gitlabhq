# frozen_string_literal: true

class AddLicensesToScanResultPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :scan_result_policies, :licenses, :jsonb, default: {}, null: false
  end
end

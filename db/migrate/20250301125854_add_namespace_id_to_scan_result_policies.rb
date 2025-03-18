# frozen_string_literal: true

class AddNamespaceIdToScanResultPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :scan_result_policies, :namespace_id, :bigint
  end
end

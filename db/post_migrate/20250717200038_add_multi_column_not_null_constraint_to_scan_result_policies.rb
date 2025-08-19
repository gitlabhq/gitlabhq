# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToScanResultPolicies < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:scan_result_policies, :project_id, :namespace_id, operator: '>=',
      limit: 1)
  end

  def down
    remove_multi_column_not_null_constraint(:scan_result_policies, :project_id, :namespace_id)
  end
end

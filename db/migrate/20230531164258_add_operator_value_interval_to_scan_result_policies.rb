# frozen_string_literal: true

class AddOperatorValueIntervalToScanResultPolicies < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  AGE_VALUE_CONSTRAINT = 'age_value_null_or_positive'

  def up
    add_column(:scan_result_policies, :age_value, :integer)
    add_column(:scan_result_policies, :age_operator, :integer, limit: 2)
    add_column(:scan_result_policies, :age_interval, :integer, limit: 2)

    add_check_constraint(:scan_result_policies, 'age_value IS NULL OR age_value >= 0', AGE_VALUE_CONSTRAINT)
  end

  def down
    remove_column(:scan_result_policies, :age_value)
    remove_column(:scan_result_policies, :age_operator)
    remove_column(:scan_result_policies, :age_interval)
  end
end

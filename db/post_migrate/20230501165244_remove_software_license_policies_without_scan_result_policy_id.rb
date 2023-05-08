# frozen_string_literal: true

class RemoveSoftwareLicensePoliciesWithoutScanResultPolicyId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1000

  def up
    each_batch_range('software_license_policies',
      scope: ->(table) { table.where(scan_result_policy_id: nil) },
      of: BATCH_SIZE) do |min, max|
      execute("DELETE FROM software_license_policies WHERE id BETWEEN #{min} AND #{max}")
    end
  end

  def down
    # NO-OP
  end
end

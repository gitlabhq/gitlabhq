# frozen_string_literal: true

class AddScanResultPolicyIdToSoftwareLicensePolicies < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_software_license_policies_on_scan_result_policy_id"

  def change
    # rubocop:disable Migration/AddReference
    add_reference :software_license_policies,
                  :scan_result_policy,
                  foreign_key: { on_delete: :cascade },
                  index: { name: INDEX_NAME },
                  null: true
    # rubocop:enable Migration/AddReference
  end
end

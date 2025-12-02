# frozen_string_literal: true

class AddLicenseOccurrenceUuidsIndexToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_security_policy_dismissals_license_occurrence_uuids'

  def up
    add_concurrent_index :security_policy_dismissals, :license_occurrence_uuids, using: :gin, name: INDEX_NAME,
      where: 'status = 1' # status: :preserved
  end

  def down
    remove_concurrent_index :security_policy_dismissals, :license_occurrence_uuids, name: INDEX_NAME
  end
end

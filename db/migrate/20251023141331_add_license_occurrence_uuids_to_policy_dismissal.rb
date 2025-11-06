# frozen_string_literal: true

class AddLicenseOccurrenceUuidsToPolicyDismissal < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'security_policy_dismissals_license_occurrence_uuids_size'

  def up
    with_lock_retries do
      add_column :security_policy_dismissals, :license_occurrence_uuids, :text, array: true,
        default: [], null: false, if_not_exists: true
    end

    add_check_constraint :security_policy_dismissals, 'CARDINALITY(license_occurrence_uuids) <= 1000', CONSTRAINT_NAME,
      validate: false
  end

  def down
    remove_column :security_policy_dismissals, :license_occurrence_uuids
  end
end

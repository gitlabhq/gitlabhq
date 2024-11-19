# frozen_string_literal: true

class AddSoftwareLicenseSpdxIdentifierToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    with_lock_retries do
      add_column :software_license_policies,
        :software_license_spdx_identifier,
        :text,
        null: true,
        if_not_exists: true
    end

    add_text_limit :software_license_policies, :software_license_spdx_identifier, 255
  end

  def down
    with_lock_retries do
      remove_column :software_license_policies, :software_license_spdx_identifier, if_exists: true
    end
  end
end

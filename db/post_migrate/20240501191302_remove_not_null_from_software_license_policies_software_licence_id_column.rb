# frozen_string_literal: true

class RemoveNotNullFromSoftwareLicensePoliciesSoftwareLicenceIdColumn < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    change_column_null :software_license_policies, :software_license_id, true
  end

  def down
    change_column_null :software_license_policies, :software_license_id, false
  end
end

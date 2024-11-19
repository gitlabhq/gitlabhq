# frozen_string_literal: true

class AddSoftwareLicenseIndexesToNameColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  CUSTOM_SOFTWARE_LICENSES_INDEX_NAME = 'idx_custom_software_licenses_lower_name'
  SOFTWARE_LICENSES_INDEX_NAME = 'idx_software_licenses_lower_name'

  def up
    add_concurrent_index :custom_software_licenses, 'LOWER(name)', name: CUSTOM_SOFTWARE_LICENSES_INDEX_NAME
    add_concurrent_index :software_licenses, 'LOWER(name)', name: SOFTWARE_LICENSES_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :custom_software_licenses, CUSTOM_SOFTWARE_LICENSES_INDEX_NAME
    remove_concurrent_index_by_name :software_licenses, SOFTWARE_LICENSES_INDEX_NAME
  end
end

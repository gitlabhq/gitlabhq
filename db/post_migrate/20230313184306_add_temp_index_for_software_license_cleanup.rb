# frozen_string_literal: true

class AddTempIndexForSoftwareLicenseCleanup < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_for_software_licenses_spdx_identifier_cleanup'

  def up
    add_concurrent_index :software_licenses, :spdx_identifier, where: 'spdx_identifier IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :software_licenses, INDEX_NAME
  end
end

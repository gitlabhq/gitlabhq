# frozen_string_literal: true

class DropSoftwareLicensesTempIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :software_licenses
  INDEX_NAME = 'tmp_index_for_software_licenses_spdx_identifier_cleanup'

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index TABLE_NAME, :spdx_identifier, where: 'spdx_identifier IS NULL', name: INDEX_NAME
  end
end

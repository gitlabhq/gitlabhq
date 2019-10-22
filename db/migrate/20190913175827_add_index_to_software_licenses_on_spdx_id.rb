# frozen_string_literal: true

class AddIndexToSoftwareLicensesOnSpdxId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :software_licenses, :spdx_identifier
  end

  def down
    remove_concurrent_index :software_licenses, :spdx_identifier
  end
end

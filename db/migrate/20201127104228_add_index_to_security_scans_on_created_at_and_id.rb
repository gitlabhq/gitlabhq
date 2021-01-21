# frozen_string_literal: true

class AddIndexToSecurityScansOnCreatedAtAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_security_scans_on_date_created_at_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_scans, "date(timezone('UTC', created_at)), id", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:security_scans, INDEX_NAME)
  end
end

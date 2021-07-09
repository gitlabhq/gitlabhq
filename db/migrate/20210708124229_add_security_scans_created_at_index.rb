# frozen_string_literal: true

class AddSecurityScansCreatedAtIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_security_scans_on_created_at'

  def up
    add_concurrent_index(:security_scans, :created_at, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:security_scans, INDEX_NAME)
  end
end

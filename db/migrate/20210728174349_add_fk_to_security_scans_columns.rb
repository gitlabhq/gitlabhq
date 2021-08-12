# frozen_string_literal: true

class AddFkToSecurityScansColumns < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_scans, :project_id
    add_concurrent_foreign_key :security_scans, :projects, column: :project_id, on_delete: :cascade

    add_concurrent_index :security_scans, :pipeline_id
  end

  def down
    remove_foreign_key :security_scans, column: :project_id
    remove_concurrent_index_by_name :security_scans, name: 'index_security_scans_on_project_id'

    remove_concurrent_index_by_name :security_scans, name: 'index_security_scans_on_pipeline_id'
  end
end

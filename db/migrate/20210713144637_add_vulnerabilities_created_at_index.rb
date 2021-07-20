# frozen_string_literal: true

class AddVulnerabilitiesCreatedAtIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_vulnerabilities_partial_devops_adoption'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :created_at], where: 'state != 1', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end

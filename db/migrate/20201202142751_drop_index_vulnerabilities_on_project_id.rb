# frozen_string_literal: true

class DropIndexVulnerabilitiesOnProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_vulnerabilities_on_project_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerabilities, :project_id, name: INDEX_NAME
  end
end

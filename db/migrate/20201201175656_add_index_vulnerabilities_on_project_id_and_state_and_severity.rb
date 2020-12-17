# frozen_string_literal: true

class AddIndexVulnerabilitiesOnProjectIdAndStateAndSeverity < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_vulnerabilities_on_project_id_and_state_and_severity'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :state, :severity], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end

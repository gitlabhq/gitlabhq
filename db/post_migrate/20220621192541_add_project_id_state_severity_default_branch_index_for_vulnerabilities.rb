# frozen_string_literal: true

class AddProjectIdStateSeverityDefaultBranchIndexForVulnerabilities < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerabilities_project_id_state_severity_default_branch'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :state, :severity, :present_on_default_branch],
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end

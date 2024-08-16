# frozen_string_literal: true

class RemoveIndexVulnerabilitiesOnProjectIdAndStateAndSeverity < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  TABLE_NAME = :vulnerabilities
  INDEX_NAME = 'index_vulnerabilities_on_project_id_and_state_and_severity'
  COLUMNS = %i[project_id state severity]

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end

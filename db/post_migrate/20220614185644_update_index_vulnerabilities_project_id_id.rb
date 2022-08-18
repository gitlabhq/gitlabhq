# frozen_string_literal: true

class UpdateIndexVulnerabilitiesProjectIdId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_vulnerabilities_project_id_and_id_on_default_branch'
  OLD_INDEX_NAME = 'index_vulnerabilities_on_project_id_and_id'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :id],
                         where: 'present_on_default_branch IS TRUE',
                         name: NEW_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index :vulnerabilities, [:project_id, :id], name: OLD_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, NEW_INDEX_NAME)
  end
end

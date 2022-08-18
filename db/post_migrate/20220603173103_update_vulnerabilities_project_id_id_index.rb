# frozen_string_literal: true

class UpdateVulnerabilitiesProjectIdIdIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'idx_vulnerabilities_partial_devops_adoption_and_default_branch'
  OLD_INDEX_NAME = 'idx_vulnerabilities_partial_devops_adoption'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :created_at, :present_on_default_branch],
                         where: 'state != 1',
                         name: NEW_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index :vulnerabilities, [:project_id, :created_at], where: 'state != 1', name: OLD_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, NEW_INDEX_NAME)
  end
end

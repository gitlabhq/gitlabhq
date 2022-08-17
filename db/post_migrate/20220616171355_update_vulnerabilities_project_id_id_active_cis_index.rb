# frozen_string_literal: true

class UpdateVulnerabilitiesProjectIdIdActiveCisIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'idx_vulnerabilities_on_project_id_and_id_active_cis_dft_branch'
  OLD_INDEX_NAME = 'index_vulnerabilities_on_project_id_and_id_active_cis'
  OLD_INDEX_FILTER_CONDITION = 'report_type = 7 AND state = ANY(ARRAY[1, 4])'
  NEW_INDEX_FILTER_CONDITION = 'report_type = 7 AND state = ANY(ARRAY[1, 4]) AND present_on_default_branch IS TRUE'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :id],
                         where: NEW_INDEX_FILTER_CONDITION,
                         name: NEW_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index :vulnerabilities, [:project_id, :id], where: OLD_INDEX_FILTER_CONDITION, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, NEW_INDEX_NAME)
  end
end

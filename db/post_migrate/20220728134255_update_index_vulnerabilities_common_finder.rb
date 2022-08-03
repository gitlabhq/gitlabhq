# frozen_string_literal: true

class UpdateIndexVulnerabilitiesCommonFinder < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_vulnerabilities_common_finder_query_on_default_branch'
  OLD_INDEX_NAME = 'index_vulnerabilites_common_finder_query'

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :state, :report_type, :present_on_default_branch,
                                            :severity, :id], name: NEW_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index :vulnerabilities, [:project_id, :state, :report_type, :severity, :id], name: OLD_INDEX_NAME

    remove_concurrent_index_by_name(:vulnerabilities, NEW_INDEX_NAME)
  end
end

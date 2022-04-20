# frozen_string_literal: true

class AddIndexToVulnerabilities < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_vulnerabilites_common_finder_query'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :vulnerabilities,
      %i[project_id state report_type severity id],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :vulnerabilities,
      INDEX_NAME
    )
  end
end

# frozen_string_literal: true

class DropRedundantVulnReadCommonProjectIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  INDEX_NAME = "index_project_vulnerability_reads_common_finder_query_desc"

  def up
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :vulnerability_reads,
      %i[project_id state report_type severity vulnerability_id],
      order: { severity: :DESC, vulnerability_id: :DESC },
      name: INDEX_NAME
    )
  end
end

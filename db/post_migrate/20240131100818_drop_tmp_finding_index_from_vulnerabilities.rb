# frozen_string_literal: true

class DropTmpFindingIndexFromVulnerabilities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = "tmp_index_vulnerabilities_on_id_finding_id_empty"

  def up
    remove_concurrent_index_by_name(
      :vulnerabilities,
      INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :vulnerabilities,
      :id,
      where: "finding_id IS NULL",
      name: INDEX_NAME
    )
  end
end

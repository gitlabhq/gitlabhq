# frozen_string_literal: true

class SyncCreateSupportingIndexForFindingIdBackfill < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_vulnerabilities_on_id_finding_id_empty"

  def up
    add_concurrent_index(
      :vulnerabilities,
      :id,
      where: "finding_id IS NULL",
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

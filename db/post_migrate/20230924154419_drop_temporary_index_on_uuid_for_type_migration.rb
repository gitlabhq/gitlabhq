# frozen_string_literal: true

class DropTemporaryIndexOnUuidForTypeMigration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "tmp_idx_vulns_on_converted_uuid"

  def up
    remove_concurrent_index_by_name(
      :vulnerability_occurrences,
      INDEX_NAME
    )
  end

  def down
    # no-op, the table is too big so we need to create the index asynchronously
  end
end

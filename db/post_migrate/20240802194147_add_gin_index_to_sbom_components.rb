# frozen_string_literal: true

class AddGinIndexToSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = "idx_sbom_components_on_name_gin"
  TABLE = "sbom_components"
  COLUMN = "name"

  def up
    add_concurrent_index(
      TABLE,
      COLUMN,
      using: "gin",
      opclass: "gin_trgm_ops",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      TABLE,
      INDEX_NAME
    )
  end
end

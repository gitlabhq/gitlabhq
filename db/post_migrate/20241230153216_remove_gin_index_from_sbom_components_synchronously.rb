# frozen_string_literal: true

class RemoveGinIndexFromSbomComponentsSynchronously < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  INDEX_NAME = "idx_sbom_components_on_name_gin"
  TABLE = "sbom_components"
  COLUMN = "name"

  def up
    remove_concurrent_index_by_name(
      TABLE,
      INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      TABLE,
      COLUMN,
      using: "gin",
      opclass: "gin_trgm_ops",
      name: INDEX_NAME
    )
  end
end

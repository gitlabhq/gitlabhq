# frozen_string_literal: true

class RemoveGinIndexFromSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'
  INDEX_NAME = "idx_sbom_components_on_name_gin"
  def up
    prepare_async_index_removal :sbom_components, :name, name: INDEX_NAME
  end

  def down
    unprepare_async_index :sbom_components, :name, name: INDEX_NAME
  end
end

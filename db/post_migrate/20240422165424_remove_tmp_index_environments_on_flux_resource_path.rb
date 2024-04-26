# frozen_string_literal: true

class RemoveTmpIndexEnvironmentsOnFluxResourcePath < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_environments_for_flux_resource_path_update'
  INDEX_WHERE = "flux_resource_path ILIKE '%kustomize.toolkit.fluxcd.io/v1beta1%'"

  def up
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end

  def down
    add_concurrent_index :environments, :id, where: INDEX_WHERE, name: INDEX_NAME
  end
end

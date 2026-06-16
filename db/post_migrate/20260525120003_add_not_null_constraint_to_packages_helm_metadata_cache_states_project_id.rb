# frozen_string_literal: true

class AddNotNullConstraintToPackagesHelmMetadataCacheStatesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  def up
    add_not_null_constraint :packages_helm_metadata_cache_states, :project_id
  end

  def down
    remove_not_null_constraint :packages_helm_metadata_cache_states, :project_id
  end
end

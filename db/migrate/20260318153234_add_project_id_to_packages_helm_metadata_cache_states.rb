# frozen_string_literal: true

class AddProjectIdToPackagesHelmMetadataCacheStates < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :packages_helm_metadata_cache_states, :project_id, :bigint
  end
end

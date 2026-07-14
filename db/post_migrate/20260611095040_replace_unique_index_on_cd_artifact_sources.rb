# frozen_string_literal: true

class ReplaceUniqueIndexOnCdArtifactSources < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  SERVICE_INDEX_NAME = 'index_cd_artifact_sources_on_service_id'

  # An artifact source is no longer 1:1 with a service (1:1 becomes 1:many),
  # so the unique index on service_id is replaced with a non-unique index.
  def up
    remove_concurrent_index_by_name :cd_artifact_sources, SERVICE_INDEX_NAME

    add_concurrent_index :cd_artifact_sources, :service_id, name: SERVICE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_artifact_sources, SERVICE_INDEX_NAME

    add_concurrent_index :cd_artifact_sources, :service_id, unique: true, name: SERVICE_INDEX_NAME
  end
end

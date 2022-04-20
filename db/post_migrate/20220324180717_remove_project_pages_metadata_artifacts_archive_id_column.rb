# frozen_string_literal: true

class RemoveProjectPagesMetadataArtifactsArchiveIdColumn < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_column :project_pages_metadata, :artifacts_archive_id
  end

  def down
    unless column_exists?(:project_pages_metadata, :artifacts_archive_id)
      add_column :project_pages_metadata, :artifacts_archive_id, :bigint
    end

    add_concurrent_index(
      :project_pages_metadata,
      :artifacts_archive_id,
      name: "index_project_pages_metadata_on_artifacts_archive_id"
    )
  end
end

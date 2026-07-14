# frozen_string_literal: true

class RemoveCdArtifactSourcesLegacyColumns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_artifact_sources

  def up
    with_lock_retries do
      remove_column TABLE_NAME, :project_id, if_exists: true
      remove_column TABLE_NAME, :source_type, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :project_id, :bigint unless column_exists?(TABLE_NAME, :project_id)
      add_column TABLE_NAME, :source_type, :smallint, default: 0 unless column_exists?(TABLE_NAME, :source_type)
    end

    add_concurrent_index TABLE_NAME, :project_id,
      where: 'project_id IS NOT NULL',
      name: :index_cd_artifact_sources_on_project_id
  end
end

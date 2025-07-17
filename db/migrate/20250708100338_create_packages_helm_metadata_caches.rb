# frozen_string_literal: true

class CreatePackagesHelmMetadataCaches < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  PROJECT_ID_AND_CHANNEL_INDEX_NAME = 'index_packages_helm_metadata_caches_on_project_id_and_channel'
  OBJECT_STORAGE_KEY_INDEX_NAME = 'index_packages_helm_metadata_caches_on_object_storage_key'

  def up
    create_table :packages_helm_metadata_caches do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.timestamps_with_timezone

      t.datetime_with_timezone :last_downloaded_at
      t.bigint :project_id, null: false
      t.integer :size, null: false
      t.integer :status, default: 0, null: false, limit: 2
      t.integer :file_store, default: 1
      t.text :channel, null: false, limit: 255
      t.text :file, null: false, limit: 255
      t.text :object_storage_key, null: false, limit: 255

      t.index %i[project_id channel], name: PROJECT_ID_AND_CHANNEL_INDEX_NAME, unique: true
      t.index :object_storage_key, name: OBJECT_STORAGE_KEY_INDEX_NAME, unique: true
    end
  end

  def down
    drop_table :packages_helm_metadata_caches
  end
end

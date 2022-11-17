# frozen_string_literal: true

class RemoveTempIndexOnProjectFeaturesWhereReleasesAccessLevelGtRepository < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_project_features_on_releases_al_and_repo_al_partial'

  def up
    remove_concurrent_index_by_name :project_features, INDEX_NAME
  end

  def down
    add_concurrent_index :project_features,
                         [:releases_access_level, :repository_access_level],
                         name: INDEX_NAME,
                         where: 'releases_access_level > repository_access_level'
  end
end

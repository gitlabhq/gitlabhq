# frozen_string_literal: true

class AddTempIndexToProjectFeaturesWhereReleasesAccessLevelGtRepository < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_project_features_on_releases_al_and_repo_al_partial'

  # Temporary index to be removed in 15.6 https://gitlab.com/gitlab-org/gitlab/-/issues/377915
  def up
    add_concurrent_index :project_features,
                         [:releases_access_level, :repository_access_level],
                         name: INDEX_NAME,
                         where: 'releases_access_level > repository_access_level'
  end

  def down
    remove_concurrent_index_by_name :project_features, INDEX_NAME
  end
end

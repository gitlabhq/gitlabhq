class AddUniqueConstraintToProjectFeaturesProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_duplicates

    add_concurrent_index :project_features, :project_id, unique: true, name: 'index_project_features_on_project_id_unique'
    remove_concurrent_index_by_name :project_features, 'index_project_features_on_project_id'
    rename_index :project_features, 'index_project_features_on_project_id_unique', 'index_project_features_on_project_id'
  end

  def down
    rename_index :project_features, 'index_project_features_on_project_id', 'index_project_features_on_project_id_old'
    add_concurrent_index :project_features, :project_id
    remove_concurrent_index_by_name :project_features, 'index_project_features_on_project_id_old'
  end

  private

  def remove_duplicates
    select_all('SELECT MAX(id) max, COUNT(id), project_id FROM project_features GROUP BY project_id HAVING COUNT(id) > 1').each do |feature|
      bad_feature_ids = select_all("SELECT id FROM project_features WHERE project_id = #{feature['project_id']} AND id <> #{feature['max']}").map { |x| x["id"] }
      execute("DELETE FROM project_features WHERE id IN(#{bad_feature_ids.join(', ')})")
    end
  end
end

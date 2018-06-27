class AddUniqueConstraintToProjectFeaturesProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class ProjectFeature < ActiveRecord::Base
    self.table_name = 'project_features'

    include EachBatch
  end

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
    features = ProjectFeature
               .select('MAX(id) AS max, COUNT(id), project_id')
               .group(:project_id)
               .having('COUNT(id) > 1')

    features.each do |feature|
      ProjectFeature
        .where(project_id: feature['project_id'])
        .where('id <> ?', feature['max'])
        .each_batch { |batch| batch.delete_all }
    end
  end
end

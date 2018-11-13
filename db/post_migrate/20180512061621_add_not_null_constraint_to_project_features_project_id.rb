class AddNotNullConstraintToProjectFeaturesProjectId < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class ProjectFeature < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_features'
  end

  def up
    ProjectFeature.where(project_id: nil).delete_all

    change_column_null :project_features, :project_id, false
  end

  def down
    change_column_null :project_features, :project_id, true
  end
end

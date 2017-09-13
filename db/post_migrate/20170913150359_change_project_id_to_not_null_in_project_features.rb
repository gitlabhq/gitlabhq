class ChangeProjectIdToNotNullInProjectFeatures < ActiveRecord::Migration
  DOWNTIME = false

  def up
    # Deletes corrupted project features
    delete_project_features_sql = "DELETE FROM project_features WHERE project_id IS NULL"
    execute(delete_project_features_sql)

    change_column_null :project_features, :project_id, false
  end

  def down
    change_column_null :project_features, :project_id, true
  end
end

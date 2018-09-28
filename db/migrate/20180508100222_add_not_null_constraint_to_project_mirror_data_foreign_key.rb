class AddNotNullConstraintToProjectMirrorDataForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class ProjectImportState < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_mirror_data'
  end

  def up
    ProjectImportState.where(project_id: nil).delete_all

    change_column_null :project_mirror_data, :project_id, false
  end

  def down
    change_column_null :project_mirror_data, :project_id, true
  end
end

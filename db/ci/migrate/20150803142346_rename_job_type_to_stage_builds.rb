class RenameJobTypeToStageBuilds < ActiveRecord::Migration
  def up
    rename_column :builds, :job_type, :stage
  end

  def down
    rename_column :builds, :stage, :job_type
  end
end

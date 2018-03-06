class AddMirrorOverwritesDivergedBranchesToProject < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :mirror_overwrites_diverged_branches, :boolean
  end
end

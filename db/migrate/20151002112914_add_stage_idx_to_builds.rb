class AddStageIdxToBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :stage_idx, :integer
  end
end

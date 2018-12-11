class AddStageIdxToBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :stage_idx, :integer
  end
end

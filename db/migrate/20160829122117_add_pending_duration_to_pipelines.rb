class AddPendingDurationToPipelines < ActiveRecord::Migration

  DOWNTIME = false

  def change
    add_column :ci_commits, :pending_duration, :integer
  end
end

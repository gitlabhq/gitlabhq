class AddDisableOverridingApproversPerMergeRequestToProject < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :disable_overriding_approvers_per_merge_request, :boolean
  end
end

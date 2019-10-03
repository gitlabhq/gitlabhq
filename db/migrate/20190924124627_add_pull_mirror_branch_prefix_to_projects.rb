# frozen_string_literal: true

class AddPullMirrorBranchPrefixToProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :pull_mirror_branch_prefix, :string, limit: 50
  end
end

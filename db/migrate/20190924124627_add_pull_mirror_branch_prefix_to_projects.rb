# frozen_string_literal: true

class AddPullMirrorBranchPrefixToProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/PreventStrings
  def change
    add_column :projects, :pull_mirror_branch_prefix, :string, limit: 50
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddColumnsToWideTables
end

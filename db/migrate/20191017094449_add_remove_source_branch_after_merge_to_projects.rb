# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRemoveSourceBranchAfterMergeToProjects < ActiveRecord::Migration[5.1]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :projects, :remove_source_branch_after_merge, :boolean # rubocop:disable Migration/AddColumnsToWideTables
  end

  def down
    remove_column :projects, :remove_source_branch_after_merge
  end
end

# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPromotedToEpicToIssues < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :issues, :promoted_to_epic_id, :integer
  end

  def down
    remove_column :issues, :promoted_to_epic_id
  end
end

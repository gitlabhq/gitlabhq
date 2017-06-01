# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPushRuleBranchName < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :push_rules, :branch_name_regex, :string
  end

  def down
    remove_column :push_rules, :branch_name_regex
  end
end

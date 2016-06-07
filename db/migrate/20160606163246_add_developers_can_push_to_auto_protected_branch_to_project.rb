# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDevelopersCanPushToAutoProtectedBranchToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects,
                            :developers_can_push_to_auto_protected_branch,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:projects, :developers_can_push_to_auto_protected_branch)
  end
end

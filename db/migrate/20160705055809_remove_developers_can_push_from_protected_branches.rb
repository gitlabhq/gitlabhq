# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDevelopersCanPushFromProtectedBranches < ActiveRecord::Migration
  def change
    remove_column :protected_branches, :developers_can_push, :boolean
  end
end

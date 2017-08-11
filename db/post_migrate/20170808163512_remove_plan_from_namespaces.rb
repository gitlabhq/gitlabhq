# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemovePlanFromNamespaces < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_column :namespaces, :plan, :string
  end
end

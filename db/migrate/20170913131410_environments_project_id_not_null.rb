# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnvironmentsProjectIdNotNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_null :environments, :project_id, false
  end

  def down
    change_column_null :environments, :project_id, true
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropDuplicateProtectedTags < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<~SQL
      DELETE FROM protected_tags
      WHERE id NOT IN (
        SELECT * FROM (
          SELECT MAX(id) FROM protected_tags
              GROUP BY name, project_id
              HAVING COUNT(*) > 1
          ) t
        )
    SQL
  end

  def down
  end
end

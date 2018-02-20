# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProtectedTagsIndex < ActiveRecord::Migration
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

    add_concurrent_index :protected_tags, [:project_id, :name], unique: true
  end

  def down
    remove_concurrent_index :protected_tags, [:project_id, :name]
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProtectedTagsIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :protected_tags, [:project_id, :name], unique: true
  end

  def down
    remove_concurrent_index :protected_tags, [:project_id, :name]
  end
end

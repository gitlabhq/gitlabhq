# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveCanPushFromKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    remove_column :keys, :can_push
  end

  def down
    add_column_with_default :keys, :can_push, :boolean, default: false, allow_null: false
  end
end

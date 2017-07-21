# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGroupAccessRequestsGroupForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_foreign_key :group_access_requests, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :group_access_requests, column: :group_id
  end
end

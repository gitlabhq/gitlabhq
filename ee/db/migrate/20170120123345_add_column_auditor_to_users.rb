# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
# rubocop:disable Migration/UpdateLargeTable
class AddColumnAuditorToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :users, :auditor, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :users, :auditor
  end
end

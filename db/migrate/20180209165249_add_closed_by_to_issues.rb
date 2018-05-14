# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddClosedByToIssues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :issues, :closed_by_id, :integer
    add_concurrent_foreign_key :issues, :users, column: :closed_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :issues, column: :closed_by_id
    remove_column :issues, :closed_by_id
  end
end

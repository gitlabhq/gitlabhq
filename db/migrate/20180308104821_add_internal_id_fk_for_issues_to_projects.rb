class AddInternalIdFkForIssuesToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:projects, :issues_iid, :integer, null: true) unless column_exists?(:projects, :issues_iid)

    add_concurrent_foreign_key :projects, :internal_ids, column: :issues_iid, on_delete: :nullify
  end

  def down
    remove_column :projects, :issues_iid
  end
end

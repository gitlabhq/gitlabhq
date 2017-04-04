class AddDevelopersCanMergeToProtectedBranches < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :protected_branches, :developers_can_merge, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :protected_branches, :developers_can_merge
  end
end

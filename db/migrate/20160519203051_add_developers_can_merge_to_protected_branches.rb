class AddDevelopersCanMergeToProtectedBranches < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_column_with_default :protected_branches, :developers_can_merge, :boolean, default: false, allow_null: false
  end
end

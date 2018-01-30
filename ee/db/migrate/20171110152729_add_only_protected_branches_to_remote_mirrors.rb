class AddOnlyProtectedBranchesToRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:remote_mirrors, :only_protected_branches, :boolean, default: false, allow_null: false)
  end

  def down
    remove_column(:remote_mirrors, :only_protected_branches)
  end
end

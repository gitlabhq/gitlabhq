class AddOnlyImportProtectedBranchesToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :projects, :only_import_protected_branches, :boolean
  end
end

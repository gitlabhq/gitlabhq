class CreateProtectedBranchUnprotectAccessLevels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  GITLAB_ACCESS_MASTER = 40

  def change
    create_table :protected_branch_unprotect_access_levels do |t|
      t.references :protected_branch, index: { name: "index_protected_branch_unprotect_access" }, foreign_key: { on_delete: :cascade }, null: false
      t.integer :access_level, default: GITLAB_ACCESS_MASTER, null: true
      t.references :user, foreign_key:  { on_delete: :cascade }, index: true
      t.integer :group_id, index: true
    end

    add_foreign_key :protected_branch_unprotect_access_levels, :namespaces, column: :group_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
  end
end

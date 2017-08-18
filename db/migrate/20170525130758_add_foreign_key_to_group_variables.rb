class AddForeignKeyToGroupVariables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_group_variables, :namespaces, column: :group_id
  end

  def down
    remove_foreign_key :ci_group_variables, column: :group_id
  end
end

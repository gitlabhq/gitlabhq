class AddForeignKeyToIssueAuthor < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:issues, :users, column: :author_id, on_delete: :nullify)
  end

  def down
    remove_foreign_key(:issues, column: :author_id)
  end
end

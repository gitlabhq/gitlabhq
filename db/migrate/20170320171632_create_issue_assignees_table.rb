# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateIssueAssigneesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_issue_assignees_on_issue_id_and_user_id'

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def up
    create_table :issue_assignees, id: false do |t|
      t.references :user, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :issue, foreign_key: { on_delete: :cascade }, null: false
    end

    add_index :issue_assignees, [:issue_id, :user_id], unique: true, name: INDEX_NAME
  end

  def down
    drop_table :issue_assignees
  end
end

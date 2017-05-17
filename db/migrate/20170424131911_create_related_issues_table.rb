class CreateRelatedIssuesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :related_issues do |t|
      t.integer :issue_id, null: false, index: true
      t.integer :related_issue_id, null: false, index: true

      t.timestamps null: true
    end

    add_index :related_issues, [:issue_id, :related_issue_id], unique: true

    add_concurrent_foreign_key :related_issues, :issues, column: :issue_id
    add_concurrent_foreign_key :related_issues, :issues, column: :related_issue_id
  end

  def down
    drop_table :related_issues
  end
end

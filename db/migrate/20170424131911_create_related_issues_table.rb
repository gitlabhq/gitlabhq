class CreateRelatedIssuesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :related_issues do |t|
      t.integer :issue_id, null: false
      t.integer :related_issue_id, null: false

      t.timestamps null: true
    end

    add_index :related_issues, [:issue_id, :related_issue_id], unique: true
  end
end

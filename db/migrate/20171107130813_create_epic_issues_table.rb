class CreateEpicIssuesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :epic_issues do |t|
      t.references :epic, null: false, index: true, foreign_key: true
      t.references :issue, null: false, index: { unique: true }, foreign_key: true

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :epic_issues
  end
end

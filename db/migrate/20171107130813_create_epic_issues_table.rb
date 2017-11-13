class CreateEpicIssuesTable < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :epic_issues do |t|
      t.references :epic, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :issue, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
    end
  end
end

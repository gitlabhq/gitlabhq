# frozen_string_literal: true

class CreateCsvIssueImports < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :csv_issue_imports do |t|
      t.bigint :project_id, null: false, index: true
      t.bigint :user_id, null: false, index: true

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :csv_issue_imports
  end
end

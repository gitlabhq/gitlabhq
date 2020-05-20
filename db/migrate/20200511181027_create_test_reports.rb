# frozen_string_literal: true

class CreateTestReports < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :requirements_management_test_reports do |t|
      t.datetime_with_timezone :created_at, null: false
      t.references :requirement, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :pipeline_id
      t.bigint :author_id
      t.integer :state, null: false, limit: 2

      t.index :pipeline_id
      t.index :author_id
    end
  end
end

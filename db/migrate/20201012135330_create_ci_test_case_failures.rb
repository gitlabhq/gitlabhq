# frozen_string_literal: true

class CreateCiTestCaseFailures < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :ci_test_case_failures do |t|
      t.datetime_with_timezone :failed_at
      t.bigint :test_case_id, null: false
      t.bigint :build_id, null: false

      t.index [:test_case_id, :failed_at, :build_id], name: 'index_test_case_failures_unique_columns', unique: true, order: { failed_at: :desc }
      t.index :build_id
      t.foreign_key :ci_test_cases, column: :test_case_id, on_delete: :cascade
      # NOTE: FK for ci_builds will be added on a separate migration as per guidelines
    end
  end

  def down
    drop_table :ci_test_case_failures
  end
end

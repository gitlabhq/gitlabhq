# frozen_string_literal: true

class CreateCiUnitTestFailures < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :ci_unit_test_failures do |t|
      t.datetime_with_timezone :failed_at, null: false
      t.bigint :unit_test_id, null: false
      t.bigint :build_id, null: false

      t.index [:unit_test_id, :failed_at, :build_id], name: 'index_unit_test_failures_unique_columns', unique: true, order: { failed_at: :desc }
      t.index :build_id
      # NOTE: Adding the index for failed_at now for later use when we do scheduled clean up
      t.index :failed_at, order: { failed_at: :desc }, name: 'index_unit_test_failures_failed_at'
      t.foreign_key :ci_unit_tests, column: :unit_test_id, on_delete: :cascade
      # NOTE: FK for ci_builds will be added on a separate migration as per guidelines
    end
  end

  def down
    drop_table :ci_unit_test_failures
  end
end

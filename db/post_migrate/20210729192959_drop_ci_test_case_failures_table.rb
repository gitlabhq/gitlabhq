# frozen_string_literal: true

class DropCiTestCaseFailuresTable < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    drop_table :ci_test_case_failures
  end

  def down
    create_table :ci_test_case_failures do |t|
      t.datetime_with_timezone :failed_at
      t.bigint :test_case_id, null: false
      t.bigint :build_id, null: false

      t.index [:test_case_id, :failed_at, :build_id], name: 'index_test_case_failures_unique_columns', unique: true, order: { failed_at: :desc }
      t.index :build_id
    end
  end
end

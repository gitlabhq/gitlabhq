# frozen_string_literal: true

class DropCiTestCasesTable < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    drop_table :ci_test_cases
  end

  def down
    create_table_with_constraints :ci_test_cases do |t|
      t.bigint :project_id, null: false
      t.text :key_hash, null: false
      t.text_limit :key_hash, 64

      t.index [:project_id, :key_hash], unique: true
    end
  end
end

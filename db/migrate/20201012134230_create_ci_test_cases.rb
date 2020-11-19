# frozen_string_literal: true

class CreateCiTestCases < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_test_cases)
      create_table :ci_test_cases do |t|
        t.bigint :project_id, null: false
        t.text :key_hash, null: false

        t.index [:project_id, :key_hash], unique: true
        # NOTE: FK for projects will be added on a separate migration as per guidelines
      end
    end

    add_text_limit :ci_test_cases, :key_hash, 64
  end

  def down
    drop_table :ci_test_cases
  end
end

# frozen_string_literal: true

class CreateCiTestBalancingAssignments < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    create_table :ci_test_balancing_assignments,
      primary_key: [:pipeline_created_at, :pipeline_id, :job_group_id, :test_split_id],
      options: 'PARTITION BY RANGE (pipeline_created_at)' do |t|
      t.datetime_with_timezone :pipeline_created_at, null: false
      t.bigint :project_id, null: false
      t.bigint :pipeline_id, null: false
      t.bigint :job_group_id, null: false
      t.bigint :test_split_id, null: false
      t.float :expected_duration
      t.integer :node_index, null: false

      t.index [:pipeline_id, :job_group_id, :node_index],
        name: 'index_ci_test_balancing_claimed_tests'
    end
  end

  def down
    drop_table :ci_test_balancing_assignments
  end
end

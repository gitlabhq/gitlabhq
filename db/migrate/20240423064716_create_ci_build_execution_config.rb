# frozen_string_literal: true

class CreateCiBuildExecutionConfig < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    create_table(:p_ci_builds_execution_configs,
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true) do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true
      t.bigint(:pipeline_id, null: false, index: true)
      t.jsonb :run_steps, default: {}, null: false
    end
  end
end

# frozen_string_literal: true

class CreateCiJobInputs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  JOB_ID_AND_NAME_INDEX_NAME = 'index_p_ci_job_inputs_on_job_id_and_name'
  PROJECT_INDEX_NAME = 'index_p_ci_job_inputs_on_project_id'

  disable_ddl_transaction!

  milestone '18.3'

  def up
    creation_opts = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table :p_ci_job_inputs, **creation_opts do |t|
      t.bigserial :id, null: false
      t.bigint :job_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false
      t.integer :input_type, null: false, limit: 2, default: 0
      t.boolean :sensitive, default: false, null: false
      t.text :name, null: false, limit: 255
      t.jsonb :value
    end

    add_concurrent_partitioned_index :p_ci_job_inputs, :project_id, name: PROJECT_INDEX_NAME
    add_concurrent_partitioned_index :p_ci_job_inputs, [:job_id, :name, :partition_id],
      name: JOB_ID_AND_NAME_INDEX_NAME, unique: true
  end

  def down
    drop_table :p_ci_job_inputs
  end
end

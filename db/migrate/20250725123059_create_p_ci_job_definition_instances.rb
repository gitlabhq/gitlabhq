# frozen_string_literal: true

class CreatePCiJobDefinitionInstances < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    opts = {
      primary_key: [:job_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)'
    }

    create_table(:p_ci_job_definition_instances, **opts) do |t|
      t.bigint :job_id, null: false
      t.bigint :job_definition_id, null: false, index: true
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true
    end
  end
end

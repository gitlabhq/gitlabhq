# frozen_string_literal: true

class CreatePCiJobDefinitions < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    index_name = :index_p_ci_job_definitions_on_project_id_and_checksum
    opts = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)'
    }

    create_table(:p_ci_job_definitions, **opts) do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :interruptible, default: false, null: false, index: true
      t.binary :checksum, null: false
      t.jsonb :config, default: {}, null: false

      t.index [:project_id, :checksum, :partition_id], unique: true, name: index_name
    end
  end
end

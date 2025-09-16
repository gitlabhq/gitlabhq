# frozen_string_literal: true

class CreatePCiJobMessages < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    opts = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table(:p_ci_job_messages, **opts) do |t|
      t.bigserial :id, null: false
      t.bigint :job_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false

      t.integer :severity, limit: 2, default: 0, null: false
      t.text :content, limit: 10_000

      t.index :project_id
      t.index :job_id
    end
  end
end

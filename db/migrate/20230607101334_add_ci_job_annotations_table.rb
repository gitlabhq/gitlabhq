# frozen_string_literal: true

class AddCiJobAnnotationsTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    options = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table(:p_ci_job_annotations, **options) do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false
      t.bigint :job_id, null: false
      t.text :name, null: false, limit: 255
      t.jsonb :data, default: [], null: false
    end
  end
end

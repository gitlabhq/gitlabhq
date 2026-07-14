# frozen_string_literal: true

class CreatePCiRuntimeEnvironments < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    options = {
      primary_key: [:id, :partition],
      options: 'PARTITION BY LIST (partition)'
    }

    create_table :p_ci_runtime_environments, **options do |t|
      t.bigserial :id, null: false
      t.bigint :partition, null: false, default: 1
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.text :environment_key, null: false, limit: 512

      t.index :project_id, name: 'index_p_ci_runtime_environments_on_project_id'
    end
  end
end

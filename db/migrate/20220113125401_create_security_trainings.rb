# frozen_string_literal: true

class CreateSecurityTrainings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    create_table :security_trainings do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :provider, null: false, foreign_key: { to_table: :security_training_providers, on_delete: :cascade }
      t.boolean :is_primary, default: false, null: false

      t.timestamps_with_timezone null: false

      # Guarantee that there will be only one primary per project
      t.index :project_id, name: 'index_security_trainings_on_unique_project_id', unique: true, where: 'is_primary IS TRUE'
    end
  end
end

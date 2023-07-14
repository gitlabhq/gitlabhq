# frozen_string_literal: true

class CreateMlModelVersions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :ml_model_versions do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false

      t.bigint :model_id, null: false # fk cascade
      t.bigint :package_id, null: true # fk nullify

      t.text :version, limit: 255, null: false

      t.index :model_id
      t.index :package_id
      t.index [:project_id, :model_id, :version], unique: true
    end
  end

  def down
    drop_table :ml_model_versions
  end
end

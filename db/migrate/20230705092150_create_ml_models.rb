# frozen_string_literal: true

class CreateMlModels < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :ml_models do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: true, index: true, on_delete: :cascade, null: false
      t.text :name, limit: 255, null: false

      t.index [:project_id, :name], unique: true
    end
  end

  def down
    drop_table :ml_models
  end
end

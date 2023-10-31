# frozen_string_literal: true

class CreateMlModelMetadata < Gitlab::Database::Migration[2.1]
  ML_MODEL_METADATA_NAME_INDEX_NAME = "unique_index_ml_model_metadata_name"

  def change
    create_table :ml_model_metadata do |t|
      t.timestamps_with_timezone null: false
      t.references :model,
        foreign_key: { to_table: :ml_models, on_delete: :cascade },
        index: false,
        null: false
      t.text :name, limit: 255, null: false
      t.text :value, limit: 5000, null: false

      t.index [:model_id, :name], unique: true, name: ML_MODEL_METADATA_NAME_INDEX_NAME
    end
  end
end

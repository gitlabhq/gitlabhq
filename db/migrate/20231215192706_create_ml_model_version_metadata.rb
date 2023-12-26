# frozen_string_literal: true

class CreateMlModelVersionMetadata < Gitlab::Database::Migration[2.2]
  ML_MODEL_VERSION_METADATA_NAME_INDEX_NAME = "unique_index_ml_model_version_metadata_name"
  milestone '16.8'

  def change
    create_table :ml_model_version_metadata do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :model_version,
        foreign_key: { to_table: :ml_model_versions, on_delete: :cascade },
        index: false,
        null: false
      t.text :name, limit: 255, null: false
      t.text :value, limit: 5000, null: false

      t.index [:model_version_id, :name], unique: true, name: ML_MODEL_VERSION_METADATA_NAME_INDEX_NAME
    end
  end
end

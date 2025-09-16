# frozen_string_literal: true

class CreateInstanceModelSelectionFeatureSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    create_table :instance_model_selection_feature_settings do |t|
      t.timestamps_with_timezone null: false
      t.integer :feature, null: false, limit: 2, index: { unique: true }
      t.text :offered_model_ref, limit: 255, null: true
      t.text :offered_model_name, limit: 255, null: true
    end
  end
end

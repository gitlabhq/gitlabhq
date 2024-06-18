# frozen_string_literal: true

class CreateAiFeatureSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    create_table :ai_feature_settings do |t|
      t.timestamps_with_timezone null: false
      t.references :ai_self_hosted_model, foreign_key: { on_delete: :cascade }, index: true, null: true
      t.integer :feature, null: false, limit: 2, index: { unique: true }
      t.integer :provider, null: false, limit: 2
    end
  end
end

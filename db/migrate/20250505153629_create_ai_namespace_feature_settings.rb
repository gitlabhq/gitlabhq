# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateAiNamespaceFeatureSettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :ai_namespace_feature_settings do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in ee/spec/factories/ai/model_selection/namespace_feature_settings.rb
      t.timestamps_with_timezone null: false
      t.references :namespace, foreign_key: { on_delete: :cascade }, index: false, null: false
      t.integer :feature, null: false, limit: 2
      t.text :offered_model_ref, limit: 255, null: true
      t.text :offered_model_name, limit: 255, null: true

      t.index [:namespace_id, :feature],
        unique: true,
        name: 'idx_namespace_feature_settings_on_namespace_id_and_feature'
    end
  end
end

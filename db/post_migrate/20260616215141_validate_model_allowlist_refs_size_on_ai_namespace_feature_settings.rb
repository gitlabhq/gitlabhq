# frozen_string_literal: true

class ValidateModelAllowlistRefsSizeOnAiNamespaceFeatureSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ai_namespace_feature_settings_model_allowlist_refs_size'

  def up
    validate_check_constraint :ai_namespace_feature_settings, CONSTRAINT_NAME
  end

  def down
    execute <<~SQL.squish
      ALTER TABLE ai_namespace_feature_settings
      DROP CONSTRAINT ai_namespace_feature_settings_model_allowlist_refs_size
    SQL
    add_check_constraint :ai_namespace_feature_settings,
      'cardinality(model_allowlist_gitlab_model_refs) <= 100',
      :ai_namespace_feature_settings_model_allowlist_refs_size,
      validate: false
  end
end

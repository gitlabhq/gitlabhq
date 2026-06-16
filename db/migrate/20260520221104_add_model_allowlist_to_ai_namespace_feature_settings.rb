# frozen_string_literal: true

class AddModelAllowlistToAiNamespaceFeatureSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ai_namespace_feature_settings_model_allowlist_refs_size'

  def up
    with_lock_retries do
      add_column :ai_namespace_feature_settings, :model_allowlist_enabled, :boolean,
        default: false, null: false, if_not_exists: true
      add_column :ai_namespace_feature_settings, :model_allowlist_gitlab_model_refs, :text,
        array: true, default: [], null: false, if_not_exists: true
    end

    add_check_constraint :ai_namespace_feature_settings,
      'CARDINALITY(model_allowlist_gitlab_model_refs) <= 100', CONSTRAINT_NAME,
      validate: false
  end

  def down
    with_lock_retries do
      remove_column :ai_namespace_feature_settings, :model_allowlist_gitlab_model_refs
      remove_column :ai_namespace_feature_settings, :model_allowlist_enabled
    end
  end
end

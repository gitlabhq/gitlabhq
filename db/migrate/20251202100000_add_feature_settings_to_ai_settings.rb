# frozen_string_literal: true

class AddFeatureSettingsToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_ai_settings_feature_settings_is_hash'

  def up
    with_lock_retries do
      add_column :ai_settings, :feature_settings, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint(
      :ai_settings,
      "(jsonb_typeof(feature_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :ai_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :ai_settings, :feature_settings, if_exists: true
    end
  end
end

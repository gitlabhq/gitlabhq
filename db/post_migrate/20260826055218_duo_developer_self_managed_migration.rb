# frozen_string_literal: true

class DuoDeveloperSelfManagedMigration < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '19.4'

  SOURCE_FEATURE = 16 # duo_agent_platform
  TARGET_FEATURE = 26 # duo_developer

  def up
    connection.execute(<<~SQL)
      INSERT INTO instance_model_selection_feature_settings (
        created_at,
        updated_at,
        feature,
        offered_model_ref,
        offered_model_name,
        model_allowlist_enabled,
        model_allowlist_gitlab_model_refs
      )
      SELECT
        NOW() AS created_at,
        NOW() AS updated_at,
        #{TARGET_FEATURE} AS feature,
        offered_model_ref,
        offered_model_name,
        model_allowlist_enabled,
        model_allowlist_gitlab_model_refs
      FROM instance_model_selection_feature_settings
      WHERE feature = #{SOURCE_FEATURE}
      ON CONFLICT (feature) DO NOTHING
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM instance_model_selection_feature_settings
      WHERE feature = #{TARGET_FEATURE}
    SQL
  end
end

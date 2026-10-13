# frozen_string_literal: true

class RecommendReviewersAssignSelfHostedMigration < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '19.5'

  SOURCE_FEATURE = 16
  TARGET_FEATURE = 28

  def up
    connection.execute(<<~SQL)
      INSERT INTO ai_feature_settings (
        created_at,
        updated_at,
        ai_self_hosted_model_id,
        feature,
        provider
      )
      SELECT
        NOW() AS created_at,
        NOW() AS updated_at,
        ai_self_hosted_model_id,
        #{TARGET_FEATURE} AS feature,
        provider
      FROM ai_feature_settings
      WHERE feature = #{SOURCE_FEATURE}
      ON CONFLICT (feature) DO NOTHING
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM ai_feature_settings
      WHERE feature = #{TARGET_FEATURE}
    SQL
  end
end

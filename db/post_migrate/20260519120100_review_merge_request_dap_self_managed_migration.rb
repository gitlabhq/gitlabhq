# frozen_string_literal: true

class ReviewMergeRequestDapSelfManagedMigration < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '19.1'

  SOURCE_FEATURE = 15 # review_merge_request
  TARGET_FEATURE = 21 # review_merge_request_dap

  def up
    connection.execute(<<~SQL)
      INSERT INTO instance_model_selection_feature_settings (
        created_at,
        updated_at,
        feature,
        offered_model_ref,
        offered_model_name
      )
      SELECT
        NOW() AS created_at,
        NOW() AS updated_at,
        #{TARGET_FEATURE} AS feature,
        offered_model_ref,
        offered_model_name
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

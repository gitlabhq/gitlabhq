# frozen_string_literal: true

class AgenticChatDotComMigration < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.7'

  SOURCE_FEATURE = 16
  TARGET_FEATURE = 17
  BATCH_SIZE = 50

  def up
    model = define_batchable_model(:ai_namespace_feature_settings, connection: connection)

    model.each_batch(column: :id, of: BATCH_SIZE) do |relation|
      relation = relation.where(feature: SOURCE_FEATURE)

      connection.execute(<<~SQL)
        INSERT INTO ai_namespace_feature_settings (
          created_at,
          updated_at,
          namespace_id,
          feature,
          offered_model_ref,
          offered_model_name
        )
        SELECT
          NOW() AS created_at,
          NOW() AS updated_at,
          namespace_id,
          #{TARGET_FEATURE} AS feature,
          offered_model_ref,
          offered_model_name
        FROM (#{relation.to_sql}) AS rows
        ON CONFLICT (namespace_id, feature) DO NOTHING
      SQL
    end
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM ai_namespace_feature_settings
      WHERE feature = #{TARGET_FEATURE}
    SQL
  end
end

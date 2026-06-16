# frozen_string_literal: true

class BackfillShowOnProfileForOptedOutUsers < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  def up
    define_batchable_model(:user_achievements).each_batch(of: 500) do |batch|
      execute(<<~SQL)
        WITH batch AS MATERIALIZED (
          #{batch.limit(500).to_sql}
        ), filtered_batch AS MATERIALIZED (
          SELECT batch.id FROM batch
          INNER JOIN user_preferences ON batch.user_id = user_preferences.user_id
          WHERE user_preferences.achievements_enabled = FALSE
          LIMIT 500
        )
        UPDATE "user_achievements"
        SET show_on_profile = FALSE
        WHERE "user_achievements"."id" IN (SELECT filtered_batch.id FROM filtered_batch)
      SQL
    end
  end

  def down; end
end

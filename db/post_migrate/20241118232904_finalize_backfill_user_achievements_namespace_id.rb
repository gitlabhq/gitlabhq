# frozen_string_literal: true

class FinalizeBackfillUserAchievementsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillUserAchievementsNamespaceId',
      table_name: :user_achievements,
      column_name: :id,
      job_arguments: [:namespace_id, :achievements, :namespace_id, :achievement_id],
      finalize: true
    )
  end

  def down; end
end

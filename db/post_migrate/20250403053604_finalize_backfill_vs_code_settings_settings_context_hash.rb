# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FinalizeBackfillVsCodeSettingsSettingsContextHash < Gitlab::Database::Migration[2.2]
  MIGRATION_NAME = 'BackfillVsCodeSettingsSettingsContextHash'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  milestone '18.0'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION_NAME,
      table_name: :vs_code_settings,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

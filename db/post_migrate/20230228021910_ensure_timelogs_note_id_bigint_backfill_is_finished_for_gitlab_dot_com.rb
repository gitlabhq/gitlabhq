# frozen_string_literal: true

class EnsureTimelogsNoteIdBigintBackfillIsFinishedForGitlabDotCom < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless should_run?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'timelogs',
      column_name: 'id',
      job_arguments: [['note_id'], ['note_id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end

  private

  def should_run?
    Gitlab.com? || Gitlab.dev_or_test_env?
  end
end

# frozen_string_literal: true

class EnsureNotesBigintBackfillIsFinishedForSelfManaged < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    return if com_or_dev_or_test_but_not_jh?

    # Same as was defined in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119913
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'notes',
      column_name: 'id',
      job_arguments: [['id'], ['id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end
end

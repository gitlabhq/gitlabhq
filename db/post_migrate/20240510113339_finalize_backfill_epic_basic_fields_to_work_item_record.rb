# frozen_string_literal: true

# NOTE: this migration specifies the incorrect arguments for BackfillEpicBasicFieldsToWorkItemRecord to be finalized.
# This leads to the BackfillEpicBasicFieldsToWorkItemRecord not being picked up to be run inline by the finalization
# step in cases when BackfillEpicBasicFieldsToWorkItemRecord does not have enough time to be finished in the background.
#
# Corrected version of the finalize migration is added to be run just after the current finalize migration:
# db/post_migrate/20240510113340_finalize_backfill_epic_basic_fields_to_work_item_record_corrected.rb
class FinalizeBackfillEpicBasicFieldsToWorkItemRecord < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    return if Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
      table_name: 'epics',
      column_name: 'id',
      job_arguments: ['group_id'],
      finalize: true
    )
  end

  def down; end
end

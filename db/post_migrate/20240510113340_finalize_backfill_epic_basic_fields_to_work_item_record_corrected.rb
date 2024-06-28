# frozen_string_literal: true

# Corrected version of the finalize migration with wrong arguments at:
# db/post_migrate/20240510113339_finalize_backfill_epic_basic_fields_to_work_item_record.rb
class FinalizeBackfillEpicBasicFieldsToWorkItemRecordCorrected < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
      table_name: 'epics',
      column_name: 'id',
      job_arguments: [nil],
      finalize: true
    )
  end

  def down; end
end

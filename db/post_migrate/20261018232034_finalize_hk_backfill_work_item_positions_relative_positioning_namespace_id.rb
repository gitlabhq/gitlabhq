# frozen_string_literal: true

class FinalizeHkBackfillWorkItemPositionsRelativePositioningNamespaceId < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWorkItemPositionsRelativePositioningNamespaceId',
      table_name: :work_item_positions,
      column_name: :work_item_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

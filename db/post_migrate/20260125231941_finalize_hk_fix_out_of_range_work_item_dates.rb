# frozen_string_literal: true

class FinalizeHkFixOutOfRangeWorkItemDates < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixOutOfRangeWorkItemDates',
      table_name: :work_item_dates_sources,
      column_name: :issue_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

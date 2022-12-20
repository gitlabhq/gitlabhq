# frozen_string_literal: true

class EnsureWorkItemTypeBackfillMigrationFinished < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillWorkItemTypeIdForIssues'

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'

    def self.id_by_type(types)
      where(namespace_id: nil, base_type: types).pluck(:base_type, :id).to_h
    end
  end

  def up
    # more types were added to the types table after the backfill run
    # so we cannot fetch all from the DB but only those that were backfilled
    relevant_types = {
      issue: 0,
      incident: 1,
      test_case: 2,
      requirement: 3,
      task: 4
    }

    MigrationWorkItemType.id_by_type(relevant_types.values).each do |base_type, type_id|
      ensure_batched_background_migration_is_finished(
        job_class_name: MIGRATION,
        table_name: :issues,
        column_name: :id,
        job_arguments: [base_type, type_id]
      )
    end
  end

  def down
    # noop
  end
end

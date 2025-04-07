# frozen_string_literal: true

class ChangeCiRunnerMachinesArchivedLfKs < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  class DeletedRecord < MigrationRecord
    self.table_name = 'loose_foreign_keys_deleted_records'

    include EachBatch
  end

  def up
    DeletedRecord
      .where(fully_qualified_table_name: 'public.ci_runner_machines_archived')
      .each_batch(column: :id) do |records|
      records.update_all(fully_qualified_table_name: 'public.ci_runner_machines')
    end
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class BackfillUpdatedAtAfterRepositoryStorageMove < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  INTERVAL = 2.minutes
  MIGRATION_CLASS = 'BackfillProjectUpdatedAtAfterRepositoryStorageMove'

  disable_ddl_transaction!

  class RepositoryStorageMove < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_repository_storage_moves'
  end

  def up
    RepositoryStorageMove.reset_column_information

    RepositoryStorageMove.select(:project_id).distinct.each_batch(of: BATCH_SIZE, column: :project_id) do |batch, index|
      migrate_in(
        INTERVAL * index,
        MIGRATION_CLASS,
        batch.pluck(:project_id)
      )
    end
  end

  def down
    # No-op
  end
end

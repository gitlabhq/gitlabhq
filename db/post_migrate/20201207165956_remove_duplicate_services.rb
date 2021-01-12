# frozen_string_literal: true

class RemoveDuplicateServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  BATCH_SIZE = 5_000
  MIGRATION = 'RemoveDuplicateServices'

  disable_ddl_transaction!

  def up
    project_ids_with_duplicates = Gitlab::BackgroundMigration::RemoveDuplicateServices::Service.project_ids_with_duplicates

    project_ids_with_duplicates.each_batch(of: BATCH_SIZE, column: :project_id) do |batch, index|
      migrate_in(
        INTERVAL * index,
        MIGRATION,
        batch.pluck(:project_id)
      )
    end
  end

  def down
  end
end

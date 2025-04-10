# frozen_string_literal: true

class CleanupRecordsWithNullNamespaceIdFromSeatAssignments < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.11'

  BATCH_SIZE = 1000

  class SeatAssignment < MigrationRecord
    include EachBatch

    self.table_name = 'subscription_seat_assignments'
  end

  def up
    # no-op - this migration is required to allow a rollback of `RemoveSeatAssignmentsNamespaceIdNotNull`
  end

  def down
    SeatAssignment.each_batch(of: BATCH_SIZE) do |relation|
      relation
        .where(namespace_id: nil)
        .delete_all
    end
  end
end

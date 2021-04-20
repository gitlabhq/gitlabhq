# frozen_string_literal: true

module Users
  class BatchStatusCleanerService
    BATCH_SIZE = 100

    # Cleanup BATCH_SIZE user_statuses records
    # rubocop: disable CodeReuse/ActiveRecord
    def self.execute(batch_size: BATCH_SIZE)
      scope = UserStatus
        .select(:user_id)
        .scheduled_for_cleanup
        .lock('FOR UPDATE SKIP LOCKED')
        .limit(batch_size)

      deleted_rows = UserStatus.where(user_id: scope).delete_all

      { deleted_rows: deleted_rows }
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

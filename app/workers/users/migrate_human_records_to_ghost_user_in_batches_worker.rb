# frozen_string_literal: true

module Users
  class MigrateHumanRecordsToGhostUserInBatchesWorker < MigrateRecordsToGhostUserInBatchesWorker # rubocop:disable Scalability/IdempotentWorker -- Idempotent declaration in the parent class
    private

    def user_types_for_processing
      ['human']
    end
  end
end

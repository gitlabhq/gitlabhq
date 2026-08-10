# frozen_string_literal: true

module Users
  class MigrateProjectBotRecordsToGhostUserInBatchesWorker < MigrateRecordsToGhostUserInBatchesWorker # rubocop:disable Scalability/IdempotentWorker -- Idempotent declaration in the parent class
    def perform
      return unless Feature.enabled?(:split_ghost_user_migration_queue_into_human_and_non_human, :instance)

      super
    end

    private

    def user_types_for_processing
      ['project_bot']
    end
  end
end

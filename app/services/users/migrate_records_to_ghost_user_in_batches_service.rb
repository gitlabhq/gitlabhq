# frozen_string_literal: true

module Users
  class MigrateRecordsToGhostUserInBatchesService
    def initialize
      @execution_tracker = Gitlab::Utils::ExecutionTracker.new
    end

    def execute
      Users::GhostUserMigration.find_each do |user_to_migrate|
        break if execution_tracker.over_limit?

        service = Users::MigrateRecordsToGhostUserService.new(user_to_migrate.user,
                                                              user_to_migrate.initiator_user,
                                                              execution_tracker)
        service.execute(hard_delete: user_to_migrate.hard_delete)
      end
    rescue Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError
      # no-op
    end

    private

    attr_reader :execution_tracker
  end
end

# frozen_string_literal: true

module Users
  class MigrateRecordsToGhostUserInBatchesService
    LIMIT_SIZE = 1000

    def initialize
      @execution_tracker = Gitlab::Utils::ExecutionTracker.new
    end

    def execute
      ghost_user_migrations.each do |job|
        break if execution_tracker.over_limit?

        service = Users::MigrateRecordsToGhostUserService.new(
          job.user,
          job.initiator_user,
          execution_tracker
        )
        service.execute(hard_delete: job.hard_delete)
      rescue Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError
        # no-op
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        reschedule(job)
      end
    end

    private

    attr_reader :execution_tracker

    def ghost_user_migrations
      Users::GhostUserMigration.consume_order.limit(LIMIT_SIZE)
    end

    def reschedule(job)
      job.update(consume_after: 30.minutes.from_now)
    end
  end
end

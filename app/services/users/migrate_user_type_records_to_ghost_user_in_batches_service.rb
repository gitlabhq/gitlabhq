# frozen_string_literal: true

module Users
  class MigrateUserTypeRecordsToGhostUserInBatchesService
    LIMIT_SIZE = 100

    def initialize(user_type:)
      @scope = scope_for(user_type)
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
        defer(job)
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        reschedule(job)
      end
    end

    private

    attr_reader :execution_tracker

    def scope_for(user_type)
      case user_type
      when :human then Users::GhostUserMigration.for_humans
      when :non_human then Users::GhostUserMigration.for_non_humans
      else
        if Feature.enabled?(:split_ghost_user_migration_queue_into_human_and_non_human, :instance)
          raise ArgumentError, "Unknown user_type: #{user_type.inspect}"
        end

        Users::GhostUserMigration
      end
    end

    def ghost_user_migrations
      @scope.consume_order.limit(LIMIT_SIZE)
    end

    def reschedule(job)
      job.update(consume_after: 30.minutes.from_now)
    end

    def defer(job)
      last_consume_after = Users::GhostUserMigration.maximum(:consume_after) || Time.current
      job.update(consume_after: 30.seconds.after(last_consume_after))
    end
  end
end

# frozen_string_literal: true

module Members
  class PruneDeletionsWorker
    include ApplicationWorker
    include CronjobChildWorker
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize

    data_consistency :sticky
    feature_category :seat_cost_management
    urgency :low
    idempotent!

    MAX_RUNNING_JOBS = 1
    MEMBER_BATCH_SIZE = 100
    SCHEDULE_BATCH_SIZE = 10

    def perform_work
      @execution_tracker = Gitlab::Utils::ExecutionTracker.new

      return unless member_deletion_schedules.any?

      process_member_deletion_schedules
    end

    def remaining_work_count(*_args)
      return 0 unless ::Feature.enabled?(:limited_capacity_member_destruction) # rubocop: disable Gitlab/FeatureFlagWithoutActor -- not required

      Members::DeletionSchedule.limit(max_running_jobs + 1).count
    end

    def max_running_jobs
      return 0 unless ::Feature.enabled?(:limited_capacity_member_destruction) # rubocop: disable Gitlab/FeatureFlagWithoutActor -- not required

      MAX_RUNNING_JOBS
    end

    private

    attr_reader :execution_tracker

    def process_member_deletion_schedules
      member_deletion_schedules.each do |member_deletion_schedule|
        remove_user_from_namespace(member_deletion_schedule)
      end
    end

    def remove_user_from_namespace(member_deletion_schedule)
      namespace = member_deletion_schedule.namespace
      user = member_deletion_schedule.user
      scheduled_by = member_deletion_schedule.scheduled_by
      memberships = ::Member.in_hierarchy(namespace).with_user(user).limit(MEMBER_BATCH_SIZE)

      destroyed_count = 0
      destroy_duration = Benchmark.realtime do
        memberships.each do |member|
          # limit deletion to execute only for 60s (execution_tracker::MAX_RUNTIME)
          break if execution_tracker.over_limit?

          ::Members::DestroyService.new(scheduled_by).execute(member, skip_subresources: true)
          destroyed_count += 1
        end
      end

      log_monitoring_data(user.id, namespace.id, destroyed_count, destroy_duration)

      # when all memberships removed, cleanup schedule:
      cleanup_schedule(member_deletion_schedule) if memberships.count === 0
    rescue Gitlab::Access::AccessDeniedError
      cleanup_schedule(member_deletion_schedule)
    end

    def member_deletion_schedules
      Members::DeletionSchedule.first(SCHEDULE_BATCH_SIZE)
    end
    strong_memoize_attr :member_deletion_schedules

    def log_monitoring_data(user_id, namespace_id, destroyed_count, destroy_duration)
      Gitlab::AppLogger.info(
        message: 'Processed scheduled member deletion',
        user_id: user_id,
        namespace_id: namespace_id,
        destroyed_count: destroyed_count,
        destroy_duration_s: destroy_duration
      )
    end

    def cleanup_schedule(member_deletion_schedule)
      member_deletion_schedule.destroy!
    end
  end
end

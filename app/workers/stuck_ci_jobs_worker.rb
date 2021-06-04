# frozen_string_literal: true

class StuckCiJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :continuous_integration
  worker_resource_boundary :cpu

  EXCLUSIVE_LEASE_KEY = 'stuck_ci_builds_worker_lease'

  BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
  BUILD_SCHEDULED_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_STUCK_TIMEOUT = 1.hour
  BUILD_LOOKBACK = 5.days

  def perform
    return unless try_obtain_lease

    Gitlab::AppLogger.info "#{self.class}: Cleaning stuck builds"

    drop(running_timed_out_builds, failure_reason: :stuck_or_timeout_failure)

    drop(
      Ci::Build.pending.updated_before(lookback: BUILD_LOOKBACK.ago, timeout: BUILD_PENDING_OUTDATED_TIMEOUT.ago),
      failure_reason: :stuck_or_timeout_failure
    )

    drop(scheduled_timed_out_builds, failure_reason: :stale_schedule)

    drop_stuck(
      Ci::Build.pending.updated_before(lookback: BUILD_LOOKBACK.ago, timeout: BUILD_PENDING_STUCK_TIMEOUT.ago),
      failure_reason: :stuck_or_timeout_failure
    )

    remove_lease
  end

  private

  def scheduled_timed_out_builds
    Ci::Build.where(status: :scheduled).where( # rubocop: disable CodeReuse/ActiveRecord
      'ci_builds.scheduled_at IS NOT NULL AND ci_builds.scheduled_at < ?',
      BUILD_SCHEDULED_OUTDATED_TIMEOUT.ago
    )
  end

  def running_timed_out_builds
    Ci::Build.running.where( # rubocop: disable CodeReuse/ActiveRecord
      'ci_builds.updated_at < ?',
      BUILD_RUNNING_OUTDATED_TIMEOUT.ago
    )
  end

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end

  def drop(builds, failure_reason:)
    fetch(builds) do |build|
      drop_build :outdated, build, failure_reason
    end
  end

  def drop_stuck(builds, failure_reason:)
    fetch(builds) do |build|
      break unless build.stuck?

      drop_build :stuck, build, failure_reason
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def fetch(builds)
    loop do
      jobs = builds.includes(:tags, :runner, project: [:namespace, :route])
        .limit(100)
        .to_a

      break if jobs.empty?

      jobs.each do |job|
        with_context(project: job.project) { yield(job) }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def drop_build(type, build, reason)
    Gitlab::AppLogger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{build.status}, failure_reason: #{reason})"
    Gitlab::OptimisticLocking.retry_lock(build, 3, name: 'stuck_ci_jobs_worker_drop_build') do |b|
      b.drop(reason)
    end
  rescue StandardError => ex
    build.doom!

    track_exception_for_build(ex, build)
  end

  def track_exception_for_build(ex, build)
    Gitlab::ErrorTracking.track_exception(ex,
        build_id: build.id,
        build_name: build.name,
        build_stage: build.stage,
        pipeline_id: build.pipeline_id,
        project_id: build.project_id
    )
  end
end

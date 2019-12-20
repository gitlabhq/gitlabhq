# frozen_string_literal: true

class StuckCiJobsWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :continuous_integration
  worker_resource_boundary :cpu

  EXCLUSIVE_LEASE_KEY = 'stuck_ci_builds_worker_lease'

  BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
  BUILD_SCHEDULED_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_STUCK_TIMEOUT = 1.hour

  def perform
    return unless try_obtain_lease

    Rails.logger.info "#{self.class}: Cleaning stuck builds" # rubocop:disable Gitlab/RailsLogger

    drop :running, BUILD_RUNNING_OUTDATED_TIMEOUT, 'ci_builds.updated_at < ?', :stuck_or_timeout_failure
    drop :pending, BUILD_PENDING_OUTDATED_TIMEOUT, 'ci_builds.updated_at < ?', :stuck_or_timeout_failure
    drop :scheduled, BUILD_SCHEDULED_OUTDATED_TIMEOUT, 'scheduled_at IS NOT NULL AND scheduled_at < ?', :stale_schedule
    drop_stuck :pending, BUILD_PENDING_STUCK_TIMEOUT, 'ci_builds.updated_at < ?', :stuck_or_timeout_failure

    remove_lease
  end

  private

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end

  def drop(status, timeout, condition, reason)
    search(status, timeout, condition) do |build|
      drop_build :outdated, build, status, timeout, reason
    end
  end

  def drop_stuck(status, timeout, condition, reason)
    search(status, timeout, condition) do |build|
      break unless build.stuck?

      drop_build :stuck, build, status, timeout, reason
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def search(status, timeout, condition)
    loop do
      jobs = Ci::Build.where(status: status)
        .where(condition, timeout.ago)
        .includes(:tags, :runner, project: :namespace)
        .limit(100)
        .to_a
      break if jobs.empty?

      jobs.each do |job|
        yield(job)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def drop_build(type, build, status, timeout, reason)
    Rails.logger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{status}, timeout: #{timeout}, reason: #{reason})" # rubocop:disable Gitlab/RailsLogger
    Gitlab::OptimisticLocking.retry_lock(build, 3) do |b|
      b.drop(reason)
    end
  rescue => ex
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

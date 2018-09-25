# frozen_string_literal: true

class StuckCiJobsWorker
  include ApplicationWorker
  include CronjobQueue

  EXCLUSIVE_LEASE_KEY = 'stuck_ci_builds_worker_lease'.freeze

  BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
  BUILD_SCHEDULED_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_STUCK_TIMEOUT = 1.hour

  def perform
    return unless try_obtain_lease

    Rails.logger.info "#{self.class}: Cleaning stuck builds"

    drop :running, condition_for_outdated_running, :stuck_or_timeout_failure
    drop :pending, condition_for_outdated_pending, :stuck_or_timeout_failure
    drop :scheduled, condition_for_outdated_scheduled, :schedule_expired
    drop_stuck :pending, condition_for_outdated_pending_stuck, :stuck_or_timeout_failure

    remove_lease
  end

  private

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end

  def drop(status, condition, reason)
    search(status, condition) do |build|
      drop_build :outdated, build, status, reason
    end
  end

  def drop_stuck(status, condition, reason)
    search(status, condition) do |build|
      break unless build.stuck?

      drop_build :stuck, build, status, reason
    end
  end

  def condition_for_outdated_running
    ["updated_at < ?", BUILD_RUNNING_OUTDATED_TIMEOUT.ago]
  end

  def condition_for_outdated_pending
    ["updated_at < ?", BUILD_PENDING_OUTDATED_TIMEOUT.ago]
  end

  def condition_for_outdated_scheduled
    ["scheduled_at <> '' && scheduled_at < ?", BUILD_SCHEDULED_OUTDATED_TIMEOUT.ago]
  end

  def condition_for_outdated_pending_stuck
    ["updated_at < ?", BUILD_PENDING_STUCK_TIMEOUT.ago]
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def search(status, condition)
    loop do
      jobs = Ci::Build.where(status: status)
        .where(*condition)
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

  def drop_build(type, build, status, reason)
    Rails.logger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{status})"
    Gitlab::OptimisticLocking.retry_lock(build, 3) do |b|
      b.drop(reason)
    end
  end
end

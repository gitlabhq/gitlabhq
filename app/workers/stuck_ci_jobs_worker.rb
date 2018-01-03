class StuckCiJobsWorker
  include ApplicationWorker
  include CronjobQueue

  EXCLUSIVE_LEASE_KEY = 'stuck_ci_builds_worker_lease'.freeze

  BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
  BUILD_PENDING_STUCK_TIMEOUT = 1.hour

  def perform
    return unless try_obtain_lease

    Rails.logger.info "#{self.class}: Cleaning stuck builds"

    drop :running, BUILD_RUNNING_OUTDATED_TIMEOUT
    drop :pending, BUILD_PENDING_OUTDATED_TIMEOUT
    drop_stuck :pending, BUILD_PENDING_STUCK_TIMEOUT

    remove_lease
  end

  private

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end

  def drop(status, timeout)
    search(status, timeout) do |build|
      drop_build :outdated, build, status, timeout
    end
  end

  def drop_stuck(status, timeout)
    search(status, timeout) do |build|
      return unless build.stuck?

      drop_build :stuck, build, status, timeout
    end
  end

  def search(status, timeout)
    loop do
      jobs = Ci::Build.where(status: status)
        .where('ci_builds.updated_at < ?', timeout.ago)
        .includes(:tags, :runner, project: :namespace)
        .limit(100)
        .to_a
      break if jobs.empty?

      jobs.each do |job|
        yield(job)
      end
    end
  end

  def drop_build(type, build, status, timeout)
    Rails.logger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{status}, timeout: #{timeout})"
    Gitlab::OptimisticLocking.retry_lock(build, 3) do |b|
      b.drop(:stuck_or_timeout_failure)
    end
  end
end

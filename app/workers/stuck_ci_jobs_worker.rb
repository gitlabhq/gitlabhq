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

    drop :running, BUILD_RUNNING_OUTDATED_TIMEOUT
    drop :pending, BUILD_PENDING_OUTDATED_TIMEOUT
    drop_stuck :pending, BUILD_PENDING_STUCK_TIMEOUT
    drop_stale_scheduled_builds

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
      drop_build :outdated, build, status, timeout, :stuck_or_timeout_failure
    end
  end

  def drop_stuck(status, timeout)
    search(status, timeout) do |build|
      break unless build.stuck?

      drop_build :stuck, build, status, timeout, :stuck_or_timeout_failure
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
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

  def drop_stale_scheduled_builds
    # `ci_builds` table has a partial index on `id` with `scheduled_at <> NULL` condition.
    # Therefore this query's first step uses Index Search, and the following expensive
    # filter `scheduled_at < ?` will only perform on a small subset (max: 100 rows)
    Ci::Build.include(EachBatch).where('scheduled_at <> NULL').each_batch(of: 100) do |relation|
      relation.where('scheduled_at < ?', BUILD_SCHEDULED_OUTDATED_TIMEOUT.ago).find_each do |build|
        drop_build(:outdated, build, :scheduled, BUILD_SCHEDULED_OUTDATED_TIMEOUT, :schedule_expired)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def drop_build(type, build, status, timeout, reason)
    Rails.logger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{status}, timeout: #{timeout}, reason: #{reason})"
    Gitlab::OptimisticLocking.retry_lock(build, 3) do |b|
      b.drop(reason)
    end
  end
end

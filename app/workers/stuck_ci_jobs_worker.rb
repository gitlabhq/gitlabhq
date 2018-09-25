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

    drop :running, :updated_at, BUILD_RUNNING_OUTDATED_TIMEOUT, :stuck_or_timeout_failure
    drop :pending, :updated_at, BUILD_PENDING_OUTDATED_TIMEOUT, :stuck_or_timeout_failure
    drop :scheduled, :scheduled_at, BUILD_SCHEDULED_OUTDATED_TIMEOUT, :schedule_expired
    drop_stuck :pending, :updated_at, BUILD_PENDING_STUCK_TIMEOUT, :stuck_or_timeout_failure

    remove_lease
  end

  private

  def try_obtain_lease
    @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
  end

  def remove_lease
    Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
  end

  def drop(status, column, timeout, reason)
    search(status, column, timeout) do |build|
      drop_build :outdated, build, status, timeout, reason
    end
  end

  def drop_stuck(status, column, timeout, reason)
    search(status, column, timeout) do |build|
      break unless build.stuck?

      drop_build :stuck, build, status, timeout, reason
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def search(status, column, timeout)
    quoted_column = ActiveRecord::Base.connection.quote_column_name(column)

    loop do
      jobs = Ci::Build.where(status: status)
        .where("#{quoted_column} < ?", timeout.ago)
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
    Rails.logger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{status}, timeout: #{timeout})"
    Gitlab::OptimisticLocking.retry_lock(build, 3) do |b|
      b.drop(reason)
    end
  end
end

class StuckCiBuildsWorker
  include Sidekiq::Worker
  include CronjobQueue

  BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
  BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
  BUILD_PENDING_STUCK_TIMEOUT = 1.hour

  def perform
    Rails.logger.info 'Cleaning stuck builds'

    drop       :running, BUILD_RUNNING_OUTDATED_TIMEOUT
    drop       :pending, BUILD_PENDING_OUTDATED_TIMEOUT
    drop_stuck :pending, BUILD_PENDING_STUCK_TIMEOUT
  end

  private

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
    builds = Ci::Build.where(status: status).where('ci_builds.updated_at < ?', timeout.ago)
    builds.joins(:project).find_each(batch_size: 50).each do |build|
      yield(build)
    end
  end

  def drop_build(type, build, status, timeout)
    Rails.logger.info "#{self.class}: Dropping #{type.to_s} build #{build.id} for runner #{build.runner_id} (status: #{status}, timeout: #{timeout})"
    build.drop
  end
end

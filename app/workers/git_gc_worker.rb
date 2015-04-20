class GitGcWorker
  include Sidekiq::Worker

  def self.schedule(*args)
    if !scheduled || args[0]
      GitGcWorker.perform_at(args[0] || first)
    end
  end

  def perform
    GitGc.cleanup
  end

  def self.scheduled
    # Sidekiq schedule stored in redis
    redis = Redis.new
    schedules = redis.keys.select { |k| k.to_s.include?('gitlab:schedule') }
    # Only expecting one schedule for Gitlab
    schedule = schedules[0]
    if schedule
      scheduled = redis.zrange(schedule, 0, -1).first
      scheduled = scheduled && scheduled.include?('GitGcWorker')
    end
    scheduled
  end

  private

  def self.first
    now = Time.now
    # Week interval in weeks
    upcoming = 7 * 24 * "#{Gitlab.config.git.gc_interval_in_weeks}".to_i
    # "Reset" to beginning of this day
    upcoming = upcoming - now.hour
    # Add or subtract to arrive at correct day
    upcoming = upcoming + 24 * ("#{Gitlab.config.git.gc_day_of_week}".to_i - now.wday)
    # Arrive at correct hour on correct weekday
    upcoming = upcoming + "#{Gitlab.config.git.gc_hour_of_day}".to_i
    # Scheduling in seconds
    3600 * upcoming
  end

end

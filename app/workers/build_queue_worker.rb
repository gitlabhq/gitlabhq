class BuildQueueWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      project.runners.select do |runner|
        if runner.can_pick?(build)
          # Inject last_update into Redis
          Gitlab::Redis.with do |redis]
            new_update = Time.new.inspect
            redis.set(runner_redis_key(runner), new_update, ex: 60.minutes)
          end
        end
      end
    end
  end

  private

  def runner_redis_key(runner)
    "#{runner.token}_#{runner.tag_list}"
  end

end

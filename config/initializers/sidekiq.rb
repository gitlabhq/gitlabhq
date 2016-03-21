SIDEKIQ_REDIS_NAMESPACE = 'resque:gitlab'

Sidekiq.configure_server do |config|
  config.redis = {
    url: Gitlab::RedisConfig.url,
    namespace: SIDEKIQ_REDIS_NAMESPACE
  }

  config.server_middleware do |chain|
    chain.add Gitlab::SidekiqMiddleware::ArgumentsLogger if ENV['SIDEKIQ_LOG_ARGUMENTS']
    chain.add Gitlab::SidekiqMiddleware::MemoryKiller if ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS']
  end

  # Sidekiq-cron: load recurring jobs from gitlab.yml
  # UGLY Hack to get nested hash from settingslogic
  cron_jobs = JSON.parse(Gitlab.config.cron_jobs.to_json)
  # UGLY hack: Settingslogic doesn't allow 'class' key
  cron_jobs.each { |k,v| cron_jobs[k]['class'] = cron_jobs[k].delete('job_class') }
  Sidekiq::Cron::Job.load_from_hash! cron_jobs

  # Database pool should be at least `sidekiq_concurrency` + 2
  # For more info, see: https://github.com/mperham/sidekiq/blob/master/4.0-Upgrade.md
  config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]
  config['pool'] = Sidekiq.options[:concurrency] + 2
  ActiveRecord::Base.establish_connection(config)
  Rails.logger.debug("Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: Gitlab::RedisConfig.url,
    namespace: SIDEKIQ_REDIS_NAMESPACE
  }
end

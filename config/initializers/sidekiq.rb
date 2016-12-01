# Custom Redis configuration
redis_config_hash = Gitlab::Redis.params
redis_config_hash[:namespace] = Gitlab::Redis::SIDEKIQ_NAMESPACE

# Default is to retry 25 times with exponential backoff. That's too much.
Sidekiq.default_worker_options = { retry: 3 }

Sidekiq.configure_server do |config|
  config.redis = redis_config_hash

  config.server_middleware do |chain|
    chain.add Gitlab::SidekiqMiddleware::ArgumentsLogger if ENV['SIDEKIQ_LOG_ARGUMENTS']
    chain.add Gitlab::SidekiqMiddleware::MemoryKiller if ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS']
    chain.add Gitlab::SidekiqMiddleware::RequestStoreMiddleware unless ENV['SIDEKIQ_REQUEST_STORE'] == '0'
  end

  # Sidekiq-cron: load recurring jobs from gitlab.yml
  # UGLY Hack to get nested hash from settingslogic
  cron_jobs = JSON.parse(Gitlab.config.cron_jobs.to_json)
  # UGLY hack: Settingslogic doesn't allow 'class' key
  cron_jobs_required_keys = %w(job_class cron)
  cron_jobs.each do |k, v|
    if cron_jobs[k] && cron_jobs_required_keys.all? { |s| cron_jobs[k].key?(s) }
      cron_jobs[k]['class'] = cron_jobs[k].delete('job_class')
    else
      cron_jobs.delete(k)
      Rails.logger.error("Invalid cron_jobs config key: '#{k}'. Check your gitlab config file.")
    end
  end
  Sidekiq::Cron::Job.load_from_hash! cron_jobs

  Gitlab::SidekiqThrottler.execute!

  # Database pool should be at least `sidekiq_concurrency` + 2
  # For more info, see: https://github.com/mperham/sidekiq/blob/master/4.0-Upgrade.md
  config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]
  config['pool'] = Sidekiq.options[:concurrency] + 2
  ActiveRecord::Base.establish_connection(config)
  Rails.logger.debug("Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")

  # Avoid autoload issue such as 'Mail::Parsers::AddressStruct'
  # https://github.com/mikel/mail/issues/912#issuecomment-214850355
  Mail.eager_autoload!
end

Sidekiq.configure_client do |config|
  config.redis = redis_config_hash
end

# The Sidekiq client API always adds the queue to the Sidekiq queue
# list, but mail_room and gitlab-shell do not. This is only necessary
# for monitoring.
config = YAML.load_file(Rails.root.join('config', 'sidekiq_queues.yml').to_s)

begin
  Sidekiq.redis do |conn|
    conn.pipelined do
      config[:queues].each do |queue|
        conn.sadd('queues', queue[0])
      end
    end
  end
rescue Redis::BaseError, SocketError, Errno::ENOENT, Errno::EAFNOSUPPORT, Errno::ECONNRESET, Errno::ECONNREFUSED
end

# Custom Queues configuration
queues_config_hash = Gitlab::Redis::Queues.params
queues_config_hash[:namespace] = Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE

# Default is to retry 25 times with exponential backoff. That's too much.
Sidekiq.default_worker_options = { retry: 3 }

enable_json_logs = Gitlab.config.sidekiq.log_format == 'json'

Sidekiq.configure_server do |config|
  config.redis = queues_config_hash

  config.server_middleware do |chain|
    chain.add Gitlab::SidekiqMiddleware::ArgumentsLogger if ENV['SIDEKIQ_LOG_ARGUMENTS'] && !enable_json_logs
    chain.add Gitlab::SidekiqMiddleware::Shutdown
    chain.add Gitlab::SidekiqMiddleware::RequestStoreMiddleware unless ENV['SIDEKIQ_REQUEST_STORE'] == '0'
    chain.add Gitlab::SidekiqStatus::ServerMiddleware
  end

  if enable_json_logs
    Sidekiq.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new
    config.options[:job_logger] = Gitlab::SidekiqLogging::StructuredLogger
  end

  config.client_middleware do |chain|
    chain.add Gitlab::SidekiqStatus::ClientMiddleware
  end

  config.on :startup do
    # Clear any connections that might have been obtained before starting
    # Sidekiq (e.g. in an initializer).
    ActiveRecord::Base.clear_all_connections!
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

  Gitlab::SidekiqVersioning.install!

  config = Gitlab::Database.config ||
    Rails.application.config.database_configuration[Rails.env]
  config['pool'] = Sidekiq.options[:concurrency]
  ActiveRecord::Base.establish_connection(config)
  Rails.logger.debug("Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")

  # Avoid autoload issue such as 'Mail::Parsers::AddressStruct'
  # https://github.com/mikel/mail/issues/912#issuecomment-214850355
  Mail.eager_autoload!
end

Sidekiq.configure_client do |config|
  config.redis = queues_config_hash

  config.client_middleware do |chain|
    chain.add Gitlab::SidekiqStatus::ClientMiddleware
  end
end

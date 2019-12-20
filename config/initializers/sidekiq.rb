require 'sidekiq/web'

def enable_reliable_fetch?
  return true unless Feature::FlipperFeature.table_exists?

  Feature.enabled?(:gitlab_sidekiq_reliable_fetcher, default_enabled: true)
end

def enable_semi_reliable_fetch_mode?
  return true unless Feature::FlipperFeature.table_exists?

  Feature.enabled?(:gitlab_sidekiq_enable_semi_reliable_fetcher, default_enabled: true)
end

# Disable the Sidekiq Rack session since GitLab already has its own session store.
# CSRF protection still works (https://github.com/mperham/sidekiq/commit/315504e766c4fd88a29b7772169060afc4c40329).
Sidekiq::Web.set :sessions, false

# Custom Queues configuration
queues_config_hash = Gitlab::Redis::Queues.params
queues_config_hash[:namespace] = Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE

# Default is to retry 25 times with exponential backoff. That's too much.
Sidekiq.default_worker_options = { retry: 3 }

if Rails.env.development?
  Sidekiq.default_worker_options[:backtrace] = true
end

enable_json_logs = Gitlab.config.sidekiq.log_format == 'json'
enable_sidekiq_memory_killer = ENV['SIDEKIQ_MEMORY_KILLER_MAX_RSS'].to_i.nonzero?
use_sidekiq_daemon_memory_killer = ENV["SIDEKIQ_DAEMON_MEMORY_KILLER"].to_i.nonzero?
use_sidekiq_legacy_memory_killer = !use_sidekiq_daemon_memory_killer
use_request_store = ENV.fetch('SIDEKIQ_REQUEST_STORE', 1).to_i.nonzero?

Sidekiq.configure_server do |config|
  config.redis = queues_config_hash

  config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator({
    metrics: Settings.monitoring.sidekiq_exporter,
    arguments_logger: ENV['SIDEKIQ_LOG_ARGUMENTS'] && !enable_json_logs,
    memory_killer: enable_sidekiq_memory_killer && use_sidekiq_legacy_memory_killer,
    request_store: use_request_store
  }))

  if enable_json_logs
    Sidekiq.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new
    config.options[:job_logger] = Gitlab::SidekiqLogging::StructuredLogger

    # Remove the default-provided handler
    config.error_handlers.reject! { |handler| handler.is_a?(Sidekiq::ExceptionHandler::Logger) }
    config.error_handlers << Gitlab::SidekiqLogging::ExceptionHandler.new
  end

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)

  config.on :startup do
    # Clear any connections that might have been obtained before starting
    # Sidekiq (e.g. in an initializer).
    ActiveRecord::Base.clear_all_connections!

    # Start monitor to track running jobs. By default, cancel job is not enabled
    # To cancel job, it requires `SIDEKIQ_MONITOR_WORKER=1` to enable notification channel
    Gitlab::SidekiqDaemon::Monitor.instance.start

    Gitlab::SidekiqDaemon::MemoryKiller.instance.start if enable_sidekiq_memory_killer && use_sidekiq_daemon_memory_killer
  end

  if enable_reliable_fetch?
    config.options[:semi_reliable_fetch] = enable_semi_reliable_fetch_mode?
    Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
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
      Rails.logger.error("Invalid cron_jobs config key: '#{k}'. Check your gitlab config file.") # rubocop:disable Gitlab/RailsLogger
    end
  end
  Sidekiq::Cron::Job.load_from_hash! cron_jobs

  Gitlab::SidekiqVersioning.install!

  db_config = Gitlab::Database.config ||
    Rails.application.config.database_configuration[Rails.env]
  db_config['pool'] = Sidekiq.options[:concurrency]
  ActiveRecord::Base.establish_connection(db_config)
  Rails.logger.debug("Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}") # rubocop:disable Gitlab/RailsLogger

  Gitlab.ee do
    Gitlab::Mirror.configure_cron_job!

    Gitlab::Geo.configure_cron_jobs!

    if Gitlab::Geo.geo_database_configured?
      Rails.configuration.geo_database['pool'] = Sidekiq.options[:concurrency]
      Geo::TrackingBase.establish_connection(Rails.configuration.geo_database)

      Rails.logger.debug("Connection Pool size for Sidekiq Server is now: #{Geo::TrackingBase.connection_pool.size} (Geo tracking database)") # rubocop:disable Gitlab/RailsLogger
    end
  end

  # Avoid autoload issue such as 'Mail::Parsers::AddressStruct'
  # https://github.com/mikel/mail/issues/912#issuecomment-214850355
  Mail.eager_autoload!

  # Ensure the whole process group is terminated if possible
  Gitlab::SidekiqSignals.install!(Sidekiq::CLI::SIGNAL_HANDLERS)
end

Sidekiq.configure_client do |config|
  config.redis = queues_config_hash

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)
end

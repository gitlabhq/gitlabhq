# frozen_string_literal: true
module SidekiqLogArguments
  def self.enabled?
    Gitlab::Utils.to_boolean(ENV['SIDEKIQ_LOG_ARGUMENTS'], default: true)
  end
end

# initialise migrated_shards on start-up to catch any malformed SIDEKIQ_MIGRATED_SHARD lists.
Gitlab::SidekiqSharding::Router.migrated_shards

# Custom Queues configuration
#
# We omit :command_builder since Sidekiq::RedisConnection performs a deep clone using
# Marshal.load(Marshal.dump(options.slice(*keys))) on the Redis config and Gitlab::Redis::CommandBuilder
# can't be referred to.
#
# We do not need the custom command builder since Sidekiq will handle the typing of Redis arguments.
queue_instance = ENV.fetch('SIDEKIQ_SHARD_NAME', Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME)
queues_config_hash = Gitlab::Redis::Queues.instances[queue_instance].params.except(:command_builder)

enable_json_logs = Gitlab.config.sidekiq.log_format != 'text'

# Sidekiq's `strict_args!` raises an exception by default in 7.0
# https://github.com/sidekiq/sidekiq/blob/31bceff64e10d501323bc06ac0552652a47c082e/docs/7.0-Upgrade.md?plain=1#L59
# We set :warn in development/test to pick out workers that try to serialise complex args
strict_args_mode = Gitlab.dev_or_test_env? ? :warn : false
Sidekiq.strict_args!(strict_args_mode)

# Perform version check before configuring server with the custome scheduled job enqueue class
unless Gem::Version.new(Sidekiq::VERSION) == Gem::Version.new('7.2.4')
  raise 'New version of Sidekiq detected, please either update the version for this check ' \
        'and update Gitlab::SidekiqSharding::ScheduledEnq is compatible.'
end

Sidekiq.configure_server do |config|
  config[:strict] = false
  config[:scheduled_enq] = Gitlab::SidekiqSharding::ScheduledEnq
  config[:queues] = Gitlab::SidekiqConfig.expand_queues(config[:queues])

  if enable_json_logs
    config.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new
    config[:job_logger] = Gitlab::SidekiqLogging::StructuredLogger

    # Remove the default-provided handler. The exception is logged inside
    # Gitlab::SidekiqLogging::StructuredLogger
    config.error_handlers.delete(Sidekiq::Config::ERROR_HANDLER)
  end

  config.logger.level = ENV.fetch("GITLAB_LOG_LEVEL", ::Logger::INFO)

  Sidekiq.logger.info "Listening on queues #{config[:queues].uniq.sort}"

  # In Sidekiq 6.x, connection pools have a size of concurrency+5.
  # ref: https://github.com/sidekiq/sidekiq/blob/v6.5.10/lib/sidekiq/redis_connection.rb#L93
  #
  # In Sidekiq 7.x, capsule connection pools have a size equal to its concurrency. Internal
  # housekeeping pool has a size of 10.
  # ref: https://github.com/sidekiq/sidekiq/blob/v7.1.6/lib/sidekiq/capsule.rb#L94
  # ref: https://github.com/sidekiq/sidekiq/blob/v7.1.6/lib/sidekiq/config.rb#L133
  #
  # We restore the concurrency+5 in Sidekiq 7.x to ensure that we do not experience resource bottlenecks with Redis
  # connections. The connections are created lazily so slightly over-provisioning a connection pool is not an issue.
  # This also increases the internal redis pool from 10 to concurrency+5.
  config.redis = queues_config_hash.merge({ size: config.concurrency + 5 })

  config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator(
    metrics: Settings.monitoring.sidekiq_exporter,
    arguments_logger: SidekiqLogArguments.enabled? && !enable_json_logs,
    skip_jobs: Gitlab::Utils.to_boolean(ENV['SIDEKIQ_SKIP_JOBS'], default: true)
  ))

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)

  config.death_handlers << Gitlab::SidekiqDeathHandler.method(:handler)

  config.on :startup do
    # Clear any connections that might have been obtained before starting
    # Sidekiq (e.g. in an initializer).
    ActiveRecord::Base.clear_all_connections! # rubocop:disable Database/MultipleDatabases

    # Start monitor to track running jobs. By default, cancel job is not enabled
    # To cancel job, it requires `SIDEKIQ_MONITOR_WORKER=1` to enable notification channel
    Gitlab::SidekiqDaemon::Monitor.instance.start

    first_sidekiq_worker = !ENV['SIDEKIQ_WORKER_ID'] || ENV['SIDEKIQ_WORKER_ID'] == '0'
    health_checks = Settings.monitoring.sidekiq_health_checks

    # Start health-check in-process server
    if first_sidekiq_worker && health_checks.enabled
      Gitlab::HealthChecks::Server.instance(
        address: health_checks.address,
        port: health_checks.port
      ).start
    end
  end

  config.on(:shutdown) do
    Gitlab::Cluster::LifecycleEvents.do_worker_stop
  end

  config[:semi_reliable_fetch] = true # Default value is false

  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)

  Gitlab::SidekiqVersioning.install!

  config[:cron_poll_interval] = Gitlab.config.cron_jobs.poll_interval
  config[:cron_poll_interval] = 0 if queue_instance != Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME

  Gitlab::SidekiqConfig::CronJobInitializer.execute

  # Avoid autoload issue such as 'Mail::Parsers::AddressStruct'
  # https://github.com/mikel/mail/issues/912#issuecomment-214850355
  Mail.eager_autoload!

  # Ensure the whole process group is terminated if possible
  Gitlab::SidekiqSignals.install!(Sidekiq::CLI::SIGNAL_HANDLERS)
end

Sidekiq.configure_client do |config|
  config.redis = queues_config_hash
  # We only need to do this for other clients. If Sidekiq-server is the
  # client scheduling jobs, we have access to the regular sidekiq logger that
  # writes to STDOUT
  config.logger = Gitlab::SidekiqLogging::ClientLogger.build
  config.logger.formatter = Gitlab::SidekiqLogging::JSONFormatter.new if enable_json_logs

  config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)
end

Gitlab::Application.configure do |config|
  config.middleware.use(Gitlab::Middleware::SidekiqShardAwarenessValidation)
end

Sidekiq::Scheduled::Poller.prepend Gitlab::Patch::SidekiqPoller
Sidekiq::Cron::Poller.prepend Gitlab::Patch::SidekiqPoller
Sidekiq::Cron::Poller.prepend Gitlab::Patch::SidekiqCronPoller

Sidekiq::Client.prepend Gitlab::SidekiqSharding::Validator::Client
Sidekiq::RedisClientAdapter::CompatMethods.prepend Gitlab::SidekiqSharding::Validator
Sidekiq::Job::Setter.prepend Gitlab::Patch::SidekiqJobSetter

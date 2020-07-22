# frozen_string_literal: true

def log_pool_size(db, previous_pool_size, current_pool_size)
  log_message = ["#{db} connection pool size: #{current_pool_size}"]

  if previous_pool_size && current_pool_size > previous_pool_size
    log_message << "(increased from #{previous_pool_size} to match thread count)"
  end

  Gitlab::AppLogger.debug(log_message.join(' '))
end

Gitlab.ee do
  # We need to initialize the Geo database before
  # setting the Geo DB connection pool size.
  if File.exist?(Rails.root.join('config/database_geo.yml'))
    Rails.application.configure do
      config.geo_database = config_for(:database_geo)
    end
  end
end

# TODO get rid of feature flag https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/495
if ENV['DB_USE_NEW_POOL_SIZE_LOGIC'] == '1'
  # Because of the way Ruby on Rails manages database connections, it is
  # important that we have at least as many connections as we have
  # threads. While there is a 'pool' setting in database.yml, it is not
  # very practical because you need to maintain it in tandem with the
  # number of application threads. Because of this we override the number
  # of allowed connections in the database connection pool based on the
  # configured number of application threads.
  #
  # Gitlab::Runtime.max_threads is the number of "user facing" application
  # threads the process has been configured with. We also have auxiliary
  # threads that use database connections. Because it is not practical to
  # keep an accurate count of the number auxiliary threads as the
  # application evolves over time, we just add a fixed headroom to the
  # number of user-facing threads. It is OK if this number is too large
  # because connections are instantiated lazily.

  headroom = (ENV["DB_POOL_HEADROOM"].presence || 10).to_i
  calculated_pool_size = Gitlab::Runtime.max_threads + headroom

  db_config = Gitlab::Database.config ||
      Rails.application.config.database_configuration[Rails.env]

  db_config['pool'] = calculated_pool_size
  ActiveRecord::Base.establish_connection(db_config)

  Gitlab.ee do
    if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
      Rails.configuration.geo_database['pool'] = calculated_pool_size
      Geo::TrackingBase.establish_connection(Rails.configuration.geo_database)
    end
  end
elsif Gitlab::Runtime.multi_threaded?
  # When running on multi-threaded runtimes like Puma or Sidekiq,
  # set the number of threads per process as the minimum DB connection pool size.
  # This is to avoid connectivity issues as was documented here:
  # https://github.com/rails/rails/pull/23057
  max_threads = Gitlab::Runtime.max_threads
  db_config = Gitlab::Database.config ||
      Rails.application.config.database_configuration[Rails.env]
  previous_db_pool_size = db_config['pool']

  db_config['pool'] = [db_config['pool'].to_i, max_threads].max + ENV["DB_POOL_HEADROOM"].to_i

  ActiveRecord::Base.establish_connection(db_config)

  current_db_pool_size = ActiveRecord::Base.connection.pool.size

  log_pool_size('DB', previous_db_pool_size, current_db_pool_size)

  Gitlab.ee do
    if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
      previous_geo_db_pool_size = Rails.configuration.geo_database['pool']
      Rails.configuration.geo_database['pool'] = max_threads
      Geo::TrackingBase.establish_connection(Rails.configuration.geo_database)
      current_geo_db_pool_size = Geo::TrackingBase.connection_pool.size
      log_pool_size('Geo DB', previous_geo_db_pool_size, current_geo_db_pool_size)
    end
  end
end

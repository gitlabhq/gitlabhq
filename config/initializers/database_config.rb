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

# When running on multi-threaded runtimes like Puma or Sidekiq,
# set the number of threads per process as the minimum DB connection pool size.
# This is to avoid connectivity issues as was documented here:
# https://github.com/rails/rails/pull/23057
if Gitlab::Runtime.multi_threaded?
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

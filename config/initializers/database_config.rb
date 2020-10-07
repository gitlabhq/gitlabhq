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

# We configure the database connection pool size automatically based on the
# configured concurrency. We also add some headroom, to make sure we don't run
# out of connections when more threads besides the 'user-facing' ones are
# running.
#
# Read more about this in doc/development/database/client_side_connection_pool.md

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

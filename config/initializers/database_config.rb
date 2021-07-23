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

db_config = Gitlab::Database.config ||
            Rails.application.config.database_configuration[Rails.env]

ActiveRecord::Base.establish_connection(
  db_config.merge(pool: Gitlab::Database.default_pool_size)
)

Gitlab.ee do
  if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
    Rails.configuration.geo_database['pool'] = Gitlab::Database.default_pool_size
    Geo::TrackingBase.establish_connection(Rails.configuration.geo_database)
  end
end

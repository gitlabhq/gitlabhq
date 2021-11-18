# frozen_string_literal: true

Gitlab.ee do
  # We need to initialize the Geo database before
  # setting the Geo DB connection pool size.
  if File.exist?(Rails.root.join('config/database_geo.yml'))
    Rails.application.configure do
      config.geo_database = config_for(:database_geo)
    end
  end
end

Gitlab.ee do
  if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
    Rails.configuration.geo_database['pool'] = Gitlab::Database.default_pool_size
    Geo::TrackingBase.establish_connection(Rails.configuration.geo_database)
  end
end

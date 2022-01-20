# frozen_string_literal: true

Gitlab.ee do
  # We need to initialize the Geo database before
  # setting the Geo DB connection pool size.
  if File.exist?(Rails.root.join('config/database_geo.yml'))
    Rails.application.configure do
      config.geo_database = config_for(:database_geo)
    end
  end

  if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
    # The Geo::TrackingBase model does not yet use connects_to. So,
    # this will not properly support geo: from config/databse.yml
    # file yet. This is ACK of the current state and will be fixed.
    Geo::TrackingBase.establish_connection(Gitlab::Database.geo_db_config_with_default_pool_size) # rubocop: disable Database/EstablishConnection
  end
end

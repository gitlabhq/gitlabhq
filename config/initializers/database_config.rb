# frozen_string_literal: true

Rails.application.reloader.to_run(:before) do
  # Make sure connects_to for Ci::ApplicationRecord gets called outside of config/routes.rb first
  # See InitializerConnections.raise_if_new_database_connection
  Ci::ApplicationRecord
end

Gitlab.ee do
  if Gitlab::Geo.geo_database_configured?
    # Make sure connects_to for geo gets called outside of config/routes.rb first
    # See InitializerConnections.raise_if_new_database_connection
    Geo::TrackingBase
  end

  if Gitlab::Runtime.sidekiq? && Gitlab::Geo.geo_database_configured?
    # The Geo::TrackingBase model does not yet use connects_to. So,
    # this will not properly support geo: from config/databse.yml
    # file yet. This is ACK of the current state and will be fixed.
    Geo::TrackingBase.establish_connection(Gitlab::Database.geo_db_config_with_default_pool_size) # rubocop: disable Database/EstablishConnection
  end
end

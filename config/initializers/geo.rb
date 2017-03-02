if Gitlab::Geo.secondary?
  Rails.application.configure do
    config.geo_database = config_for(:database_geo)
  end
end

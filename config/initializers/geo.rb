if File.exist?(Rails.root.join('config/database_geo.yml'))
  Rails.application.configure do
    config.geo_database = config_for(:database_geo)
  end
end

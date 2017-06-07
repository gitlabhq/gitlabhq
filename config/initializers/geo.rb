if File.exist?(Rails.root.join('config/database_geo.yml')) &&
    Gitlab::Geo.secondary_role_enabled?
  Rails.application.configure do
    config.geo_database = config_for(:database_geo)
  end
end

begin
  if Gitlab::Geo.primary?
    Gitlab::Geo.current_node.update_clone_url!
  end
rescue
  warn 'WARNING: Unable to check/update clone_url_prefix for Geo'
end

if File.exist?(Rails.root.join('config/database_geo.yml')) &&
    Gitlab::Geo.secondary_role_enabled?
  Rails.application.configure do
    config.geo_database = config_for(:database_geo)
  end
end

begin
  # Avoid using the database if this is run in a Rake task
  if Gitlab::Geo.primary_role_enabled?
    Gitlab::Geo.current_node&.update_clone_url!
  end
rescue => e
  warn "WARNING: Unable to check/update clone_url_prefix for Geo: #{e}"
end

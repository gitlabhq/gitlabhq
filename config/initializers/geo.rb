Gitlab.ee do
  if File.exist?(Rails.root.join('config/database_geo.yml'))
    Rails.application.configure do
      config.geo_database = config_for(:database_geo)
    end
  end

  begin
    if Gitlab::Geo.connected? && Gitlab::Geo.primary?
      Gitlab::Geo.current_node&.update_clone_url!
    end
  rescue => e
    warn "WARNING: Unable to check/update clone_url_prefix for Geo: #{e}"
  end
end

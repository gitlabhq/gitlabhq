class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Gitlab::Geo.secondary_role_enabled? && Gitlab::Geo.geo_database_configured?
    establish_connection Rails.configuration.geo_database
  end
end

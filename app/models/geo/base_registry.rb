class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Gitlab::Geo.secondary_role_enabled?
    establish_connection Rails.configuration.geo_database
  end
end

class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Gitlab::Geo.configured? && (Gitlab::Geo.secondary? || Rails.env.test?)
    establish_connection Rails.configuration.geo_database
  end
end

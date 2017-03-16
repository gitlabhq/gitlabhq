class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Rails.configuration.respond_to?(:geo_database) && (Gitlab::Geo.secondary? || Rails.env.test?)
    establish_connection Rails.configuration.geo_database
  end
end

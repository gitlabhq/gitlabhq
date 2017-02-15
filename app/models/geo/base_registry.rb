class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  establish_connection Rails.configuration.geo_database
end

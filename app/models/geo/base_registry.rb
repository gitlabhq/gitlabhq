class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Gitlab::Geo.secondary? || (Rails.env.test? && Rails.configuration.respond_to?(:geo_database))
    establish_connection Rails.configuration.geo_database
  end
end

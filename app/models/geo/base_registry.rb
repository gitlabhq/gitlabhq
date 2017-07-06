class Geo::BaseRegistry < ActiveRecord::Base
  self.abstract_class = true

  if Gitlab::Geo.geo_database_configured?
    establish_connection Rails.configuration.geo_database
  end

  def self.connection
    raise 'Geo secondary database is not configured' unless Gitlab::Geo.geo_database_configured?

    super
  end
end

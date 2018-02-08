# This module is intended to centralize all database access to the secondary
# tracking database for Geo.
module Geo
  class TrackingBase < ActiveRecord::Base
    self.abstract_class = true

    SecondaryNotConfigured = Class.new(StandardError)

    if ::Gitlab::Geo.geo_database_configured?
      establish_connection Rails.configuration.geo_database
    end

    def self.connection
      unless ::Gitlab::Geo.geo_database_configured?
        raise SecondaryNotConfigured.new('Geo secondary database is not configured')
      end

      super
    end
  end
end

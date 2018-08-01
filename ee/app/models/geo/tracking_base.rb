# This module is intended to centralize all database access to the secondary
# tracking database for Geo.
module Geo
  class TrackingBase < ActiveRecord::Base
    self.abstract_class = true

    NOT_CONFIGURED_MSG     = 'Geo secondary database is not configured'.freeze
    SecondaryNotConfigured = Class.new(StandardError)

    if ::Gitlab::Geo.geo_database_configured?
      establish_connection Rails.configuration.geo_database
    end

    def self.connection
      unless ::Gitlab::Geo.geo_database_configured?
        message = NOT_CONFIGURED_MSG
        message += "\nIn the GDK root, try running `make geo-setup`" if Rails.env.development?
        raise SecondaryNotConfigured.new(message)
      end

      # Don't call super because LoadBalancing::ActiveRecordProxy will intercept it
      retrieve_connection
    rescue ActiveRecord::NoDatabaseError
      raise SecondaryNotConfigured.new(NOT_CONFIGURED_MSG)
    end
  end
end

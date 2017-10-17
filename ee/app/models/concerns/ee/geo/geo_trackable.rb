module EE
  module Geo
    module GeoTrackable
      extend ActiveSupport::Concern

      included do
        if ::Gitlab::Geo.geo_database_configured?
          establish_connection Rails.configuration.geo_database
        end
      end

      class_methods do
        def self.connection
          raise 'Geo secondary database is not configured' unless ::Gitlab::Geo.geo_database_configured?

          super
        end
      end
    end
  end
end

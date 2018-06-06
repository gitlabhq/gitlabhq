module API
  module Helpers
    class APIRouteBuilder
      include ::API::Helpers::RelatedResourcesHelpers

      def self.expose_url(api_route_name, params)
        builder.expose_url(builder.send(api_route_name, params))
      end

      def self.builder
        @builder ||= new
      end
    end
  end
end

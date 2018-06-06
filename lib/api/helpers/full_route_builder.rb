module API
  module Helpers
    class FullRouteBuilder
      include ::API::Helpers::RelatedResourcesHelpers

      def self.full_url(api_route_name, params)
        return unless builder.respond_to? api_route_name

        builder.expose_url(builder.send(api_route_name, params))
      end

      def self.builder
        @builder ||= new
      end
    end
  end
end

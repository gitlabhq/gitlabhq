module API
  module Helpers
    class FullRouteBuilder
      include Singleton
      include ::API::Helpers::RelatedResourcesHelpers

      def self.full_url(api_route_name, params)
        return unless instance.respond_to? api_route_name

        instance.expose_url(instance.send(api_route_name, params))
      end
    end
  end
end

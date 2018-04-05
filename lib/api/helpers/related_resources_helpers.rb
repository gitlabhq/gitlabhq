module API
  module Helpers
    module RelatedResourcesHelpers
      include GrapeRouteHelpers::NamedRouteMatcher

      def issues_available?(project, options)
        available?(:issues, project, options[:current_user])
      end

      def mrs_available?(project, options)
        available?(:merge_requests, project, options[:current_user])
      end

      def expose_url(path)
        url_options = Gitlab::Application.routes.default_url_options
        protocol, host, port = url_options.slice(:protocol, :host, :port).values

        URI::Generic.build(scheme: protocol, host: host, port: port, path: path).to_s
      end

      private

      def available?(feature, project, current_user)
        project.feature_available?(feature, current_user)
      end
    end
  end
end

module API
  module Helpers
    module RelatedResourcesHelpers
      include GrapePathHelpers::NamedRouteMatcher

      def issues_available?(project, options)
        available?(:issues, project, options[:current_user])
      end

      def mrs_available?(project, options)
        available?(:merge_requests, project, options[:current_user])
      end

      def expose_url(path)
        url_options = Gitlab::Application.routes.default_url_options
        protocol, host, port, script_name = url_options.values_at(:protocol, :host, :port, :script_name)

        # Using a blank component at the beginning of the join we ensure
        # that the resulted path will start with '/'. If the resulted path
        # does not start with '/', URI::Generic#build will fail
        path_with_script_name = File.join('', [script_name, path].select(&:present?))

        URI::Generic.build(scheme: protocol, host: host, port: port, path: path_with_script_name).to_s
      end

      private

      def available?(feature, project, current_user)
        project.feature_available?(feature, current_user)
      end
    end
  end
end

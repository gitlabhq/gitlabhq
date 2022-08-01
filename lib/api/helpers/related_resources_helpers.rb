# frozen_string_literal: true

module API
  module Helpers
    module RelatedResourcesHelpers
      include GrapePathHelpers::NamedRouteMatcher

      def issues_available?(project, options)
        available?(:issues, project, options[:current_user])
      end

      def project_feature_string_access_level(project, feature)
        project.project_feature&.string_access_level(feature)
      end

      def mrs_available?(project, options)
        available?(:merge_requests, project, options[:current_user])
      end

      def expose_path(path)
        Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, path)
      end

      def expose_url(path)
        url_options = Gitlab::Application.routes.default_url_options
        protocol, host, port, script_name = url_options.values_at(:protocol, :host, :port, :script_name)

        # Using a blank component at the beginning of the join we ensure
        # that the resulted path will start with '/'. If the resulted path
        # does not start with '/', URI::Generic#new will fail
        path_with_script_name = File.join('', [script_name, path].select(&:present?))

        URI::Generic.new(protocol, nil, host, port, nil, path_with_script_name, nil, nil, nil, URI::RFC3986_PARSER, true).to_s
      end

      private

      def available?(feature, project, current_user)
        project.feature_available?(feature, current_user)
      end
    end
  end
end

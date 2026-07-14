# frozen_string_literal: true

module API
  class Base < Grape::API::Instance # rubocop:disable API/Base
    include ::Gitlab::EndpointAttributes

    class << self
      def feature_category_for_app(app)
        feature_category_for_action(path_for_app(app))
      end

      def urgency_for_app(app)
        urgency_for_action(path_for_app(app))
      end

      def path_for_app(app)
        normalize_path(app.namespace, app.options[:path].first)
      end

      def endpoint_id_for_route(route)
        "#{route.request_method} #{route.origin}"
      end

      # Opt out of the global Current.organization assignment performed in
      # API::API's before_validation hook. Use this on classes whose endpoints
      # set Current.organization from non-user request state (for example the
      # runner's own organization) inside the endpoint body, where Grape's
      # filter ordering would otherwise let the global fallback win.
      def skip_global_organization_setup!
        @skip_global_organization_setup = true
      end

      def skip_global_organization_setup?
        @skip_global_organization_setup == true
      end

      def route(methods, paths = ['/'], route_options = {}, &block)
        actions = Array(paths).map { |path| normalize_path(namespace, path) }
        if category = route_options.delete(:feature_category)
          feature_category(category, actions)
        end

        if target = route_options.delete(:urgency)
          urgency(target, actions)
        end

        super
      end

      private

      def normalize_path(namespace, path)
        [namespace.presence, path.to_s.chomp('/').presence].compact.join('/')
      end
    end
  end
end

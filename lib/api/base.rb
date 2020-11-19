# frozen_string_literal: true

module API
  class Base < Grape::API::Instance # rubocop:disable API/Base
    include ::Gitlab::WithFeatureCategory

    class << self
      def feature_category_for_app(app)
        feature_category_for_action(path_for_app(app))
      end

      def path_for_app(app)
        normalize_path(app.namespace, app.options[:path].first)
      end

      def route(methods, paths = ['/'], route_options = {}, &block)
        if category = route_options.delete(:feature_category)
          feature_category(category, Array(paths).map { |path| normalize_path(namespace, path) })
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

# frozen_string_literal: true

# partial backport of https://github.com/rails/rails/pull/38169
# this is in order to be able to re-order rack middlewares.

unless Rails::Configuration::MiddlewareStackProxy.method_defined?(:move)
  module Rails
    module Configuration
      class MiddlewareStackProxy
        def move(*args, &block)
          @operations << ->(middleware) { middleware.send(__method__, *args, &block) }
        end
        ruby2_keywords(:move) if respond_to?(:ruby2_keywords, true)
      end
    end
  end
end

Rails.application.config.middleware.move(1, ActionDispatch::RequestId)
Rails.application.config.middleware.insert(1, Labkit::Middleware::Rack)

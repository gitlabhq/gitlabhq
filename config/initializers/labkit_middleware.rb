# frozen_string_literal: true

# partial backport of https://github.com/rails/rails/pull/38169
# this is in order to be able to re-order rack middlewares.

if ActionDispatch::MiddlewareStack.method_defined?(:move)
  warn "`move` is now defined in in ActionDispatch itself: https://github.com/rails/rails/pull/38169, please remove this patch from #{__FILE__}"
else
  module ActionDispatch
    class MiddlewareStack
      def move(target, source)
        source_index = assert_index(source, :before)
        source_middleware = middlewares.delete_at(source_index)

        target_index = assert_index(target, :before)
        middlewares.insert(target_index, source_middleware)
      end
    end
  end
end

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
Rails.application.config.middleware.insert_after(ActionDispatch::RequestId, Labkit::Middleware::Rack)

# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStoreWrapper < Wrapper
      class << self
        # overrides Wrapper's pool to use the multistore connection pool
        def with
          multistore_pool.with do |multistore|
            yield multistore
          end
        end
        alias_method :then, :with

        def multistore_pool
          @multistore_pool ||= MultiStoreConnectionPool.new(size: pool_size, name: pool_name) { multistore }
        end

        def pool_name
          "#{store_name}MultiStore".underscore
        end

        def multistore
          raise NotImplementedError
        end
      end
    end
  end
end

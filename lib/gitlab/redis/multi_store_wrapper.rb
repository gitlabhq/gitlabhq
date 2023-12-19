# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStoreWrapper < Wrapper
      class << self
        def with
          multistore_pool.with do |multistore|
            multistore.with_borrowed_connection do
              yield multistore
            end
          end
        end

        def multistore_pool
          @multistore_pool ||= ConnectionPool.new(size: pool_size, name: pool_name) { multistore }
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

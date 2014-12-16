# Monkey-patch Redis::Store to make 'setex' and 'expire' work with namespacing

module Gitlab
  class Redis
    class Store
      module Namespace
        # Redis::Store#setex in redis-store 1.1.4 does not respect namespaces;
        # this new method does.
        def setex(key, expires_in, value, options=nil)
          namespace(key) { |key| super(key, expires_in, value) }
        end

        # Redis::Store#expire in redis-store 1.1.4 does not respect namespaces;
        # this new method does.
        def expire(key, expires_in)
          namespace(key) { |key| super(key, expires_in) }
        end

        private

        # Our new definitions of #setex and #expire above assume that the
        # #namespace method exists. Because we cannot be sure of that, we
        # re-implement the #namespace method from Redis::Store::Namespace so
        # that it is available for all Redis::Store instances, whether they use
        # namespacing or not.
        #
        # Based on lib/redis/store/namespace.rb L49-51 (redis-store 1.1.4)
        def namespace(key)
          if @namespace
            yield interpolate(key)
          else
            # This Redis::Store instance does not use a namespace so we should
            # just pass through the key.
            yield key
          end
        end
      end
    end
  end
end

Redis::Store.class_eval do
  include Gitlab::Redis::Store::Namespace
end

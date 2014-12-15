# Monkey-patch Redis::Store to make 'setex' and 'expire' work with namespacing

module Gitlab
  class Redis
    class Store
      module Namespace
        def setex(key, expires_in, value, options=nil)
          namespace(key) { |key| super(key, expires_in, value) }
        end

        def expire(key, expires_in)
          namespace(key) { |key| super(key, expires_in) }
        end
      end
    end
  end
end

Redis::Store.class_eval do
  include Gitlab::Redis::Store::Namespace
end

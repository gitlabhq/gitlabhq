module Gitlab
  module Cache
    # This module provides a simple way to cache values in RequestStore,
    # and the cache key would be based on the class name, method name,
    # customized instance level values, and arguments.
    #
    # A simple example:
    #
    # class UserAccess
    #   extend Gitlab::Cache::RequestStoreWrap
    #
    #   request_store_wrap_key do
    #     [user.id, project.id]
    #   end
    #
    #   request_store_wrap def can_push_to_branch?(ref)
    #     # ...
    #   end
    # end
    #
    # This way, the result of `can_push_to_branch?` would be cached in
    # `RequestStore.store` based on the cache key.
    module RequestStoreWrap
      def self.extended(klass)
        return if klass < self

        extension = Module.new
        klass.const_set(:RequestStoreWrapExtension, extension)
        klass.prepend(extension)
      end

      def request_store_wrap_key(&block)
        if block_given?
          @request_store_wrap_key = block
        else
          @request_store_wrap_key
        end
      end

      def request_store_wrap(method_name)
        const_get(:RequestStoreWrapExtension)
          .send(:define_method, method_name) do |*args|
            return super(*args) unless RequestStore.active?

            klass = self.class
            key = [klass.name,
                   method_name,
                   *instance_exec(&klass.request_store_wrap_key),
                   *args].join(':')

            if RequestStore.store.key?(key)
              RequestStore.store[key]
            else
              RequestStore.store[key] = super(*args)
            end
          end
      end
    end
  end
end

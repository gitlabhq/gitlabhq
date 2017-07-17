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

      def request_store_wrap(method_name, &method_key_block)
        const_get(:RequestStoreWrapExtension).module_eval do
          define_method(method_name) do |*args|
            store =
              if RequestStore.active?
                RequestStore.store
              else
                ivar_name = # ! and ? cannot be used as ivar name
                  "@#{method_name.to_s.tr('!', "\u2605").tr('?', "\u2606")}"

                instance_variable_get(ivar_name) ||
                  instance_variable_set(ivar_name, {})
              end

            key = send("#{method_name}_cache_key", args)

            if store.key?(key)
              store[key]
            else
              store[key] = super(*args)
            end
          end

          cache_key_method_name = "#{method_name}_cache_key"

          define_method(cache_key_method_name) do |args|
            klass = self.class

            instance_key = instance_exec(&klass.request_store_wrap_key) if
              klass.request_store_wrap_key

            method_key = instance_exec(&method_key_block) if method_key_block

            [klass.name, method_name, *instance_key, *method_key, *args]
              .join(':')
          end

          private cache_key_method_name
        end
      end
    end
  end
end

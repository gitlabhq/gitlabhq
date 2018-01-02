module Gitlab
  module Cache
    # This module provides a simple way to cache values in RequestStore,
    # and the cache key would be based on the class name, method name,
    # optionally customized instance level values, optionally customized
    # method level values, and optional method arguments.
    #
    # A simple example:
    #
    # class UserAccess
    #   extend Gitlab::Cache::RequestCache
    #
    #   request_cache_key do
    #     [user&.id, project&.id]
    #   end
    #
    #   request_cache def can_push_to_branch?(ref)
    #     # ...
    #   end
    # end
    #
    # This way, the result of `can_push_to_branch?` would be cached in
    # `RequestStore.store` based on the cache key. If RequestStore is not
    # currently active, then it would be stored in a hash saved in an
    # instance variable, so the cache logic would be the same.
    # Here's another example using customized method level values:
    #
    # class Commit
    #   extend Gitlab::Cache::RequestCache
    #
    #   def author
    #     User.find_by_any_email(author_email.downcase)
    #   end
    #   request_cache(:author) { author_email.downcase }
    # end
    #
    # So that we could have different strategies for different methods
    #
    module RequestCache
      def self.extended(klass)
        return if klass < self

        extension = Module.new
        klass.const_set(:RequestCacheExtension, extension)
        klass.prepend(extension)
      end

      attr_accessor :request_cache_key_block

      def request_cache_key(&block)
        if block_given?
          self.request_cache_key_block = block
        else
          request_cache_key_block
        end
      end

      def request_cache(method_name, &method_key_block)
        const_get(:RequestCacheExtension).module_eval do
          cache_key_method_name = "#{method_name}_cache_key"

          define_method(method_name) do |*args|
            store =
              if RequestStore.active?
                RequestStore.store
              else
                ivar_name = # ! and ? cannot be used as ivar name
                  "@cache_#{method_name.to_s.tr('!?', "\u2605\u2606")}"

                instance_variable_get(ivar_name) ||
                  instance_variable_set(ivar_name, {})
              end

            key = __send__(cache_key_method_name, args) # rubocop:disable GitlabSecurity/PublicSend

            store.fetch(key) { store[key] = super(*args) }
          end

          define_method(cache_key_method_name) do |args|
            klass = self.class

            instance_key = instance_exec(&klass.request_cache_key) if
              klass.request_cache_key

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

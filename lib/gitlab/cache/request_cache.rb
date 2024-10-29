# frozen_string_literal: true

module Gitlab
  module Cache
    # See https://docs.gitlab.com/ee/development/utilities.html#requestcache
    module RequestCache
      def self.extended(klass)
        return if klass < self

        extension = Module.new
        klass.const_set(:RequestCacheExtension, extension)
        klass.prepend(extension)
      end

      attr_accessor :request_cache_key_block

      def request_cache_key(&block)
        if block
          self.request_cache_key_block = block
        else
          request_cache_key_block
        end
      end

      def request_cache(method_name, &method_key_block)
        const_get(:RequestCacheExtension, false).module_eval do
          cache_key_method_name = "#{method_name}_cache_key"

          define_method(method_name) do |*args|
            store =
              if Gitlab::SafeRequestStore.active?
                Gitlab::SafeRequestStore.store
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

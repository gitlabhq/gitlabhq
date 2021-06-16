# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseChecker
      include Gitlab::Utils::StrongMemoize

      def validate!
        raise NotImplementedError
      end

      private

      def updated_from_web?
        protocol == 'web'
      end

      def validate_once(resource)
        Gitlab::SafeRequestStore.fetch(cache_key_for_resource(resource)) do
          yield(resource)

          true
        end
      end

      def cache_key_for_resource(resource)
        "git_access:#{checker_cache_key}:#{resource.cache_key}"
      end

      def checker_cache_key
        self.class.name.demodulize.underscore
      end
    end
  end
end

Gitlab::Checks::BaseChecker.prepend_mod_with('Gitlab::Checks::BaseChecker')

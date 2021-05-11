# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseChecker
      include Gitlab::Utils::StrongMemoize

      attr_reader :change_access
      delegate(*ChangeAccess::ATTRIBUTES, to: :change_access)

      def initialize(change_access)
        @change_access = change_access
      end

      def validate!
        raise NotImplementedError
      end

      private

      def creation?
        Gitlab::Git.blank_ref?(oldrev)
      end

      def deletion?
        Gitlab::Git.blank_ref?(newrev)
      end

      def update?
        !creation? && !deletion?
      end

      def updated_from_web?
        protocol == 'web'
      end

      def tag_exists?
        project.repository.tag_exists?(tag_name)
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

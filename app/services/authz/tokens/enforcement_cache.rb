# frozen_string_literal: true

module Authz
  module Tokens
    # Per-request cache of whether a root namespace enforces granular tokens.
    # Shared by the GraphQL boundary preloader and AuthorizeGranularScopesService
    # so a namespace's enforcement setting is only queried once per request.
    class EnforcementCache
      GRANULAR_TOKENS_ENFORCEMENT_CACHE_KEY = :granular_tokens_enforcement_cache

      def any_enforced?(root_namespace_ids)
        fetch_missing(root_namespace_ids)

        root_namespace_ids.any? { |id| cache[id] }
      end

      private

      def fetch_missing(root_namespace_ids)
        missing = root_namespace_ids.compact.uniq.reject { |id| cache.key?(id) }
        return if missing.empty?

        enforced = ::Namespace.id_in(missing).with_namespace_settings.index_by(&:id)

        missing.each do |id|
          namespace = enforced[id]
          cache[id] = namespace.present? && namespace.granular_tokens_enforced?
        end
      end

      def cache
        @cache ||= Gitlab::SafeRequestStore.fetch(GRANULAR_TOKENS_ENFORCEMENT_CACHE_KEY) { {} }
      end
    end
  end
end

# frozen_string_literal: true

module Resolvers
  module Search
    # Subclasses must not override ready?; use verify_additional_preconditions! instead. The
    # ratchet spec in search_resolvers_rate_limit_spec.rb enforces this.
    class BaseResolver < ::Resolvers::BaseResolver # rubocop:disable Graphql/ResolverType -- Child class defines the type
      include ::Search::SearchRateLimitable

      def ready?(**args)
        verify_search_rate_limit!(**args)
        verify_additional_preconditions!(**args)
        super
      end

      private

      def verify_additional_preconditions!(**args)
        # Subclasses override this; intentionally a no-op here.
      end
    end
  end
end

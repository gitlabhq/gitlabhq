module Gitlab
  # Class for counting and caching the number of issuables per state.
  class IssuablesCountForState
    # The name of the RequestStore cache key.
    CACHE_KEY = :issuables_count_for_state

    # The state values that can be safely casted to a Symbol.
    STATES = %w[opened closed merged all].freeze

    # finder - The finder class to use for retrieving the issuables.
    def initialize(finder)
      @finder = finder
      @cache =
        if RequestStore.active?
          RequestStore[CACHE_KEY] ||= initialize_cache
        else
          initialize_cache
        end
    end

    def for_state_or_opened(state = nil)
      self[state || :opened]
    end

    # Returns the count for the given state.
    #
    # state - The name of the state as either a String or a Symbol.
    #
    # Returns an Integer.
    def [](state)
      state = state.to_sym if cast_state_to_symbol?(state)

      cache_for_finder[state] || 0
    end

    private

    def cache_for_finder
      @cache[@finder]
    end

    def cast_state_to_symbol?(state)
      state.is_a?(String) && STATES.include?(state)
    end

    def initialize_cache
      Hash.new { |hash, finder| hash[finder] = finder.count_by_state }
    end
  end
end

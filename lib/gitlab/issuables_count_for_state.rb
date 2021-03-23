# frozen_string_literal: true

module Gitlab
  # Class for counting and caching the number of issuables per state.
  class IssuablesCountForState
    # The name of the Gitlab::SafeRequestStore cache key.
    CACHE_KEY = :issuables_count_for_state

    # The state values that can be safely casted to a Symbol.
    STATES = %w[opened closed merged all].freeze

    attr_reader :project

    def self.declarative_policy_class
      'IssuablePolicy'
    end

    # finder - The finder class to use for retrieving the issuables.
    # fast_fail - restrict counting to a shorter period, degrading gracefully on
    # failure
    def initialize(finder, project = nil, fast_fail: false)
      @finder = finder
      @project = project
      @fast_fail = fast_fail
      @cache = Gitlab::SafeRequestStore[CACHE_KEY] ||= initialize_cache
    end

    def for_state_or_opened(state = nil)
      self[state || :opened]
    end

    def fast_fail?
      !!@fast_fail
    end

    # Define method for each state
    STATES.each do |state|
      define_method(state) { self[state] }
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
      Hash.new { |hash, finder| hash[finder] = perform_count(finder) }
    end

    def perform_count(finder)
      return finder.count_by_state unless fast_fail?

      fast_count_by_state_attempt!

      # Determining counts when referring to issuable titles or descriptions can
      # be very expensive, and involve the database reading gigabytes of data
      # for a relatively minor piece of functionality. This may slow index pages
      # by seconds in the best case, or lead to a statement timeout in the worst
      # case.
      #
      # In time, we may be able to use elasticsearch or postgresql tsv columns
      # to perform the calculation more efficiently. Until then, use a shorter
      # timeout and return -1 as a sentinel value if it is triggered
      begin
        ApplicationRecord.with_fast_read_statement_timeout do
          finder.count_by_state
        end
      rescue ActiveRecord::QueryCanceled => err
        fast_count_by_state_failure!

        Gitlab::ErrorTracking.track_exception(
          err,
          params: finder.params,
          current_user_id: finder.current_user&.id,
          issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/249180'
        )

        Hash.new(-1)
      end
    end

    def fast_count_by_state_attempt!
      Gitlab::Metrics.counter(
        :gitlab_issuable_fast_count_by_state_total,
        "Count of total calls to IssuableFinder#count_by_state with fast failure"
      ).increment
    end

    def fast_count_by_state_failure!
      Gitlab::Metrics.counter(
        :gitlab_issuable_fast_count_by_state_failures_total,
        "Count of failed calls to IssuableFinder#count_by_state with fast failure"
      ).increment
    end
  end
end

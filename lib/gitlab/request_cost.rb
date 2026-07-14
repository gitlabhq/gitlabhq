# frozen_string_literal: true

module Gitlab
  # Per-request accumulator keyed by resource symbol so additional cost
  # sources can be added
  class RequestCost # rubocop:disable Gitlab/NamespacedClass -- mirrors Gitlab::RequestContext, a top-level per-request object
    KEY = :request_cost

    # Returned when SafeRequestStore is not active so callers don't need to guard.
    class NullCost # rubocop:disable Gitlab/NamespacedClass -- internal companion to RequestCost
      def add(_amount, resource:); end

      def get(_resource)
        0
      end
    end

    NULL = NullCost.new.freeze

    def self.current
      return NULL unless Gitlab::SafeRequestStore.active?

      Gitlab::SafeRequestStore[KEY] ||= new
    end

    def initialize
      @scores = Hash.new(0)
    end

    def add(amount, resource:)
      @scores[resource] += amount
    end

    def get(resource)
      @scores[resource]
    end
  end
end

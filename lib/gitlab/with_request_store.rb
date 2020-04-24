# frozen_string_literal: true

module Gitlab
  module WithRequestStore
    def with_request_store(&block)
      # Skip enabling the request store if it was already active. Whatever
      # instantiated the request store first is responsible for clearing it
      return yield if RequestStore.active?

      enabling_request_store(&block)
    end

    private

    def enabling_request_store
      RequestStore.begin!
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end

    extend self
  end
end

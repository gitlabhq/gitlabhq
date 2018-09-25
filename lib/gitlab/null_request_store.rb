# frozen_string_literal: true

# Used by Gitlab::SafeRequestStore
module Gitlab
  # The methods `begin!`, `clear!`, and `end!` are not defined because they
  # should only be called directly on `RequestStore`.
  class NullRequestStore
    def store
      {}
    end

    def active?
    end

    def read(key)
    end

    def [](key)
    end

    def write(key, value)
      value
    end

    def []=(key, value)
      value
    end

    def exist?(key)
      false
    end

    def fetch(key, &block)
      yield
    end

    def delete(key, &block)
      yield(key) if block_given?
    end
  end
end

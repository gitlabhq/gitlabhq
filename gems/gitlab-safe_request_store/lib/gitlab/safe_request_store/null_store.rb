# frozen_string_literal: true

module Gitlab
  module SafeRequestStore
    # The methods `begin!`, `clear!`, and `end!` are not defined because they
    # should only be called directly on `RequestStore`.
    class NullStore
      def store
        {}
      end

      def active?
        # no-op
      end

      def read(_key)
        # no-op
      end

      def [](_key)
        # no-op
      end

      def write(_key, value)
        value
      end

      def []=(_key, value)
        value
      end

      def exist?(_key)
        false
      end

      def fetch(_key, &_block)
        yield
      end

      def delete(key, &block)
        yield(key) if block
      end
    end
  end
end

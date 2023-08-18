# frozen_string_literal: true

require 'forwardable'

require 'request_store'

require_relative "safe_request_store/version"
require_relative "safe_request_store/null_store"

module Gitlab
  module SafeRequestStore
    NULL_STORE = NullStore.new

    class << self
      extend Forwardable

      # These methods should always run directly against RequestStore
      def_delegators :RequestStore, :clear!, :begin!, :end!, :active?

      # These methods will run against NullStore if RequestStore is disabled
      def_delegators :store, :read, :[], :write, :[]=, :exist?, :fetch, :delete

      def store
        if RequestStore.active?
          RequestStore
        else
          NULL_STORE
        end
      end

      # Access to the backing storage of the request store. This returns an object
      # with `[]` and `[]=` methods that does not discard values.
      #
      # This can be useful if storage is needed for a delimited purpose, and the
      # forgetful nature of the null store is undesirable.
      def storage
        store.store
      end

      # This method accept an options hash to be compatible with
      # ActiveSupport::Cache::Store#write method. The options are
      # not passed to the underlying cache implementation because
      # RequestStore#write accepts only a key, and value params.
      def write(key, value, _options = nil)
        store.write(key, value)
      end

      def delete_if(&_block)
        return unless RequestStore.active?

        storage.delete_if { |k, _v| yield(k) }
      end

      def ensure_request_store(&block)
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
    end
  end
end

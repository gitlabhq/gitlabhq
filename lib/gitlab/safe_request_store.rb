# frozen_string_literal: true

module Gitlab
  module SafeRequestStore
    NULL_STORE = Gitlab::NullRequestStore.new

    class << self
      # These methods should always run directly against RequestStore
      delegate :clear!, :begin!, :end!, :active?, to: :RequestStore

      # These methods will run against NullRequestStore if RequestStore is disabled
      delegate :read, :[], :write, :[]=, :exist?, :fetch, :delete, to: :store
    end

    def self.store
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
    def self.storage
      store.store
    end

    # This method accept an options hash to be compatible with
    # ActiveSupport::Cache::Store#write method. The options are
    # not passed to the underlying cache implementation because
    # RequestStore#write accepts only a key, and value params.
    def self.write(key, value, options = nil)
      store.write(key, value)
    end

    def self.delete_if(&block)
      return unless RequestStore.active?

      storage.delete_if { |k, v| block.call(k) }
    end
  end
end

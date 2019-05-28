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

    # This method accept an options hash to be compatible with
    # ActiveSupport::Cache::Store#write method. The options are
    # not passed to the underlying cache implementation because
    # RequestStore#write accepts only a key, and value params.
    def self.write(key, value, options = nil)
      store.write(key, value)
    end
  end
end

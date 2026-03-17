# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class BaseSubscriptions
        def initialize(store)
          @store = store
        end

        attr_reader :store
      end
    end
  end
end

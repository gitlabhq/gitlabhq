# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class NamespacesSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Namespaces::UpdateRootStatisticsWorker, to: ::Projects::ProjectDeletedEvent
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class NamespacesSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Namespaces::UpdateRootStatisticsWorker, to: ::Projects::ProjectDeletedEvent
          store.subscribe ::Namespaces::InvalidateDescendantsCacheWorker, to: ::Projects::ProjectArchivedEvent
        end
      end
    end
  end
end

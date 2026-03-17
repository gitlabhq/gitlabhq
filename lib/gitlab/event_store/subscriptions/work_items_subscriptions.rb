# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class WorkItemsSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::WorkItems::UserPreferences::DestroyWorker, to: ::Members::DestroyedEvent
          store.subscribe ::WorkItems::ProcessProjectTransferEventsWorker,
            to: ::Projects::ProjectTransferedEvent,
            if: ->(event) { ::WorkItems::ProcessProjectTransferEventsWorker.handles_event?(event) }

          store.subscribe ::WorkItems::ProcessGroupTransferEventsWorker,
            to: ::Groups::GroupTransferedEvent,
            if: ->(event) { ::WorkItems::ProcessGroupTransferEventsWorker.handles_event?(event) }
        end
      end
    end
  end
end

Gitlab::EventStore::Subscriptions::WorkItemsSubscriptions.prepend_mod

# frozen_string_literal: true

# Gitlab::EventStore is a simple pub-sub mechanism that lets you publish
# domain events and use Sidekiq workers as event handlers.
#
# It can be used to decouple domains from different bounded contexts
# by publishing domain events and let any interested parties subscribe
# to them.
#
module Gitlab
  module EventStore
    Error = Class.new(StandardError)
    InvalidEvent = Class.new(Error)
    InvalidSubscriber = Class.new(Error)

    def self.publish(event)
      instance.publish(event)
    end

    def self.instance
      @instance ||= Store.new { |store| configure!(store) }
    end

    # Define all event subscriptions using:
    #
    #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent)
    #
    # It is possible to subscribe to a subset of events matching a condition:
    #
    #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent), if: ->(event) { event.data == :some_value }
    #
    def self.configure!(store)
      ###
      # Add subscriptions here:

      store.subscribe ::MergeRequests::UpdateHeadPipelineWorker, to: ::Ci::PipelineCreatedEvent
      store.subscribe ::Namespaces::UpdateRootStatisticsWorker, to: ::Projects::ProjectDeletedEvent

      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Pages::PageDeployedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Pages::PageDeletedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Projects::ProjectDeletedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Projects::ProjectCreatedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Projects::ProjectPathChangedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Projects::ProjectArchivedEvent
      store.subscribe ::Pages::InvalidateDomainCacheWorker, to: ::Projects::ProjectTransferedEvent

      store.subscribe ::MergeRequests::CreateApprovalEventWorker, to: ::MergeRequests::ApprovedEvent
    end
    private_class_method :configure!
  end
end

Gitlab::EventStore.prepend_mod_with('Gitlab::EventStore')

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

    class << self
      def publish(event)
        instance.publish(event)
      end

      def publish_group(events)
        instance.publish_group(events)
      end

      def instance
        @instance ||= Store.new { |store| configure!(store) }
      end

      private

      # Define all event subscriptions using:
      #
      #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent)
      #
      # It is possible to subscribe to a subset of events matching a condition:
      #
      #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent), if: ->(event) { event.data == :some_value }
      #
      def configure!(store)
        ###
        # Add subscriptions here:

        store.subscribe ::MergeRequests::UpdateHeadPipelineWorker, to: ::Ci::PipelineCreatedEvent
        store.subscribe ::Namespaces::UpdateRootStatisticsWorker, to: ::Projects::ProjectDeletedEvent
        store.subscribe ::Ci::Runners::UpdateProjectRunnersOwnerWorker, to: ::Projects::ProjectDeletedEvent

        store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker,
          to: ::MergeRequests::AutoMerge::TitleDescriptionUpdateEvent
        store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker, to: ::MergeRequests::DraftStateChangeEvent
        store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker, to: ::MergeRequests::DiscussionsResolvedEvent
        store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker, to: ::MergeRequests::MergeableEvent
        store.subscribe ::MergeRequests::CreateApprovalEventWorker, to: ::MergeRequests::ApprovedEvent
        store.subscribe ::MergeRequests::CreateApprovalNoteWorker, to: ::MergeRequests::ApprovedEvent
        store.subscribe ::MergeRequests::ResolveTodosAfterApprovalWorker, to: ::MergeRequests::ApprovedEvent
        store.subscribe ::MergeRequests::ExecuteApprovalHooksWorker, to: ::MergeRequests::ApprovedEvent
        store.subscribe ::Ml::ExperimentTracking::AssociateMlCandidateToPackageWorker,
          to: ::Packages::PackageCreatedEvent,
          if: ->(event) { ::Ml::ExperimentTracking::AssociateMlCandidateToPackageWorker.handles_event?(event) }
        store.subscribe ::Ci::InitializePipelinesIidSequenceWorker, to: ::Projects::ProjectCreatedEvent
        store.subscribe ::Pages::DeletePagesDeploymentWorker, to: ::Projects::ProjectArchivedEvent
        store.subscribe ::Pages::ResetPagesDefaultDomainRedirectWorker, to: ::Pages::Domains::PagesDomainDeletedEvent
        store.subscribe ::MergeRequests::ProcessDraftNotePublishedWorker, to: ::MergeRequests::DraftNotePublishedEvent

        subscribe_to_member_destroyed_events(store)
      end

      def subscribe_to_member_destroyed_events(store)
        store.subscribe ::WorkItems::UserPreferences::DestroyWorker, to: ::Members::DestroyedEvent
      end
    end
  end
end

Gitlab::EventStore.prepend_mod_with('Gitlab::EventStore')

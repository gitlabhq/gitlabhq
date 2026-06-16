# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class MergeRequestsSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::MergeRequests::UpdateHeadPipelineWorker, to: ::Ci::PipelineCreatedEvent
          store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker,
            to: ::MergeRequests::AutoMerge::TitleDescriptionUpdateEvent
          store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker, to: ::MergeRequests::DraftStateChangeEvent
          store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker,
            to: ::MergeRequests::DiscussionsResolvedEvent
          store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker, to: ::MergeRequests::MergeableEvent
          # Only fire when no pipeline was produced. When a pipeline exists,
          # Ci::Pipeline.after_transition re-enqueues AutoMergeProcessWorker
          # on completion, so this subscription would be redundant.
          store.subscribe ::MergeRequests::ProcessAutoMergeFromEventWorker,
            to: ::MergeRequests::PipelineCreationCompletedEvent,
            if: ->(event) { event.data[:pipeline_id].nil? }
          store.subscribe ::MergeRequests::CreateApprovalEventWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::CreateApprovalNoteWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::ResolveTodosAfterApprovalWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::ExecuteApprovalHooksWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::ProcessDraftNotePublishedWorker, to: ::MergeRequests::DraftNotePublishedEvent
        end
      end
    end
  end
end

Gitlab::EventStore::Subscriptions::MergeRequestsSubscriptions.prepend_mod

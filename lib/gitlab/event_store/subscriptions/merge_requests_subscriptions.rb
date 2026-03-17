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

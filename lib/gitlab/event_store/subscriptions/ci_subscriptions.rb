# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class CiSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Ci::TrackPipelineTriggerEventsWorker, to: ::Ci::PipelineCreatedEvent
          # The DuoWorkflows::Workflow pipeline can never be manual which is why a constraint on manual is added.
          # In future if this needs to be used at other places where manual needs to be considered,
          # then remove the if block and verify that DuoWorkflows::Workflow works as expected.
          store.subscribe ::Ci::Workloads::UpdateWorkloadStatusEventWorker, to: ::Ci::PipelineFinishedEvent,
            if: ->(event) { event.data[:status] != 'manual' }
          store.subscribe ::Ci::InitializePipelinesIidSequenceWorker, to: ::Projects::ProjectCreatedEvent
          store.subscribe ::Ci::PipelineSchedules::DeactivateSchedulesWorker,
            to: ::ProjectAuthorizations::AuthorizationsRemovedEvent
          store.subscribe ::Ci::PipelineSchedules::DeactivateSchedulesWorker,
            to: ::ProjectAuthorizations::AuthorizationsAddedEvent
        end
      end
    end
  end
end

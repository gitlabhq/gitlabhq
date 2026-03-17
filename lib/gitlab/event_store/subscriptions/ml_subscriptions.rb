# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class MlSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Ml::ExperimentTracking::AssociateMlCandidateToPackageWorker,
            to: ::Packages::PackageCreatedEvent,
            if: ->(event) { ::Ml::ExperimentTracking::AssociateMlCandidateToPackageWorker.handles_event?(event) }
        end
      end
    end
  end
end

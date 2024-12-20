# frozen_string_literal: true

module Ml
  module ExperimentTracking
    class AssociateMlCandidateToPackageWorker
      include Gitlab::EventStore::Subscriber

      data_consistency :always
      feature_category :mlops
      urgency :low
      idempotent!

      def handle_event(event)
        candidate_iid = event.data[:version].delete_prefix(Ml::Candidate::PACKAGE_PREFIX)
        return unless (candidate = Ml::Candidate.with_project_id_and_iid(event.data[:project_id], candidate_iid))
        return unless (package = Packages::Package.find_by_id(event.data[:id]))

        candidate.package = package
        candidate.save!
      end

      def self.handles_event?(event)
        event.ml_model? && Ml::Experiment.package_for_experiment?(event.data[:name])
      end
    end
  end
end

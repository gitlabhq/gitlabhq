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
        candidate = Ml::Candidate.find_from_package_name(event.data[:name])
        package = Packages::Package.find_by_id(event.data[:id])

        return unless candidate && package

        candidate.package = package
        candidate.save!
      end

      def self.handles_event?(event)
        event.generic? && Ml::Candidate.candidate_id_for_package(event.data[:name]).present?
      end
    end
  end
end

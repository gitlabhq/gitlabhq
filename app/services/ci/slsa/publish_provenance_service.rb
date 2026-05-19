# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class PublishProvenanceService < ::BaseService
      ATTESTATION_PUBLISHERS = [SupplyChain::ArtifactProvenancePublisher,
        SupplyChain::ContainerProvenancePublisher].freeze

      def initialize(build)
        @build = build
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        unless @build.project.public?
          return ServiceResponse.error(message: "Attestation is only enabled for public projects")
        end

        all_attestations = []
        all_succeeded = true
        ATTESTATION_PUBLISHERS.each do |publisher_class|
          next unless publisher_class.should_publish?(@build)

          begin
            publisher = publisher_class.new(@build)
            attestations, success = publisher.publish

            all_attestations += attestations
            all_succeeded = false unless success
          rescue SupplyChain::ProvenancePublisher::Error => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @build.project.id)

            all_succeeded = false
          end
        end

        if all_succeeded
          message = all_attestations.any? ? "Attestations persisted" : "No attestations performed"

          ServiceResponse.success(message: message,
            payload: { attestations: all_attestations })
        else
          ServiceResponse.error(message: "Error occurred when publishing attestations",
            payload: { attestations: all_attestations })
        end
      end
    end
  end
end

Ci::Slsa::PublishProvenanceService.prepend_mod

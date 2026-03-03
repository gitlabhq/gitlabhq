# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class PublishProvenanceService < ::BaseService
      def initialize(build)
        @build = build
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        unless @build.project.public?
          return ServiceResponse.error(message: "Attestation is only enabled for public projects")
        end

        attest_artifacts
      end

      private

      def attest_artifacts
        artifact_publisher = SupplyChain::ArtifactProvenancePublisher.new(@build)

        return artifact_publisher.publish if artifact_publisher.should_publish?

        ServiceResponse.error(message: "No attestations performed")
      end
    end
  end
end

Ci::Slsa::PublishProvenanceService.prepend_mod

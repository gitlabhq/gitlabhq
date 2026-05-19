# frozen_string_literal: true

module SupplyChain
  class ContainerProvenancePublisher < ProvenancePublisher
    def self.should_publish?(build)
      ::SupplyChain.publish_container_provenance?(build)
    end

    def publish
      if image_digest
        return [[], true] if successful_attestation?(image_digest)

        attestations = []
        attestation, success = attest_container(image_digest)
        attestations << attestation if attestation

        return [attestations, success]
      end

      log(message: "Image digest not present in build")

      [[], false]
    end

    private

    def image_digest
      digest_variable = @build.variables[SupplyChain::IMAGE_DIGEST_VARIABLE]

      return unless digest_variable

      digest = digest_variable.value
      digest = digest.split('@')[1] if digest.include?('@')
      digest = digest.split(':')[1] if digest.include?(":")

      digest
    end
    strong_memoize_attr :image_digest

    def attest_container(hash)
      attestation, duration = cosign_attest_blob(hash: hash)
      log(message: "Container attestation successful", duration: duration, hash: hash)

      [attestation, true]
    rescue StandardError => e
      log(message: "Container attestation failure", hash: hash)

      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @build.project.id)

      attestation = persist_error_attestation(subject_digest: hash)

      [attestation, false]
    end
  end
end

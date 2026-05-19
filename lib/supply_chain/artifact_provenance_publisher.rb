# frozen_string_literal: true

module SupplyChain
  class ArtifactProvenancePublisher < ProvenancePublisher
    def self.should_publish?(build)
      ::SupplyChain.publish_artifact_provenance?(build)
    end

    def publish
      reader = SupplyChain::ArtifactsReader.new(@build)

      all_successful = true
      attestations = []
      reader.files do |artifact_path, file_input_stream|
        hash = hash(file_input_stream)

        next if successful_attestation?(hash)

        attestation, success = attest_artifact(artifact_path, hash)
        attestations << attestation if attestation

        all_successful = false unless success
      end

      [attestations, all_successful]
    end

    private

    def attest_artifact(artifact_path, hash)
      blob_name = File.basename(artifact_path)
      begin
        attestation, duration = cosign_attest_blob(blob_name: blob_name, hash: hash)
        log(message: "Attestation successful", duration: duration, path: artifact_path, hash: hash,
          blob_name: blob_name)

        [attestation, true]
      rescue StandardError => e
        log(message: "Attestation failure", path: artifact_path, hash: hash, blob_name: blob_name)

        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @build.project.id)

        attestation = persist_error_attestation(subject_digest: hash)

        [attestation, false]
      end
    end

    def hash(file_input_stream)
      sha = Digest::SHA256.new
      sha << file_input_stream.read(HASH_READ_CHUNK_SIZE) until file_input_stream.eof?
      sha.hexdigest
    end
  end
end

# frozen_string_literal: true

module SupplyChain
  class ArtifactProvenancePublisher < ProvenancePublisher
    def should_publish?
      ::SupplyChain.publish_artifact_provenance?(@build)
    end

    def publish
      return ServiceResponse.error(message: "Missing required variable SIGSTORE_ID_TOKEN") unless id_token

      reader = SupplyChain::ArtifactsReader.new(@build)

      all_successful = true
      attestations = []
      reader.files do |artifact_path, file_input_stream|
        hash = hash(file_input_stream)

        next if successful_attestation?(hash)

        attestation, success = attest_artifact(artifact_path, hash)
        attestations << attestation

        all_successful = false unless success
      end

      if all_successful
        return ServiceResponse.success(message: "Attestations persisted",
          payload: { attestations: attestations })
      end

      ServiceResponse.error(message: "Attestation failure", payload: { attestations: attestations })
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

        attestation = persist_attestation!(status: :error, subject_digest: hash)

        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @build.project.id)

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

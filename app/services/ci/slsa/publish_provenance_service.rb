# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class PublishProvenanceService < ::BaseService
      HASH_READ_CHUNK_SIZE = 1.megabyte

      Error = Class.new(StandardError)
      AttestationFailure = Class.new(Error)
      InvalidInput = Class.new(Error)

      def initialize(build)
        @build = build
        @logger = Gitlab::AppJsonLogger
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        unless @build.project.public?
          return ServiceResponse.error(message: "Attestation is only enabled for public projects")
        end

        id_token = @build.variables["SIGSTORE_ID_TOKEN"]&.value
        return ServiceResponse.error(message: "Missing required variable SIGSTORE_ID_TOKEN") unless id_token

        reader = SupplyChain::ArtifactsReader.new(@build)

        reader.files do |artifact_path, file_input_stream|
          blob_name = File.basename(artifact_path)
          hash = hash(file_input_stream)
          predicate = SupplyChain::Slsa::ProvenanceStatement::Predicate.from_build(@build).to_json

          @logger.info(class: self.class.name, message: "Performing attestation for artifact", hash: hash,
            path: artifact_path, build_id: @build.id)

          attestation, duration = attest_blob!(blob_name: blob_name, hash: hash, predicate: predicate,
            id_token: id_token)

          @logger.info(class: self.class.name, message: "Attestation successful", hash: hash, blob_name: blob_name,
            attestation: attestation, duration: duration, build_id: @build.id)
        end

        ServiceResponse.success(message: "OK")
      end

      def hash(file_input_stream)
        sha = Digest::SHA256.new
        sha << file_input_stream.read(HASH_READ_CHUNK_SIZE) until file_input_stream.eof?
        sha.hexdigest
      end

      def ci_server_url
        Gitlab.config.gitlab.url
      end

      def attest_blob!(blob_name:, hash:, predicate:, id_token:)
        validate_id_token!(id_token)
        validate_blob_name!(blob_name)
        validate_hash!(hash)

        attestation = nil
        result = nil
        Tempfile.create(["attestation-", ".bundle"]) do |bundle_file|
          base_command = [
            'cosign',
            'attest-blob',
            '--new-bundle-format',
            '--predicate', '-',
            '--type', 'slsaprovenance1',
            '--hash', hash,
            '--identity-token', id_token,
            '--oidc-issuer', ci_server_url,
            '--yes',
            '--bundle', bundle_file.path
          ]

          prefixed_path = "./#{blob_name}"
          command = base_command + optional_arguments + ['--', prefixed_path]

          result = Gitlab::Popen.popen_with_detail(command) do |stdin|
            stdin.write(predicate)
          end

          bundle_file.rewind
          attestation = bundle_file.read
        end

        return attestation, result.duration if result.status.success?

        error = result.stderr
        raise AttestationFailure, "Attestation for #{hash} failed after #{result.duration}s: #{error}"
      end

      def validate_id_token!(id_token)
        # Can be path or literal according to documentation.
        Gitlab::PathTraversal.check_path_traversal!(id_token)

        # This prevents invalid input as defense in depth when passing to Popen3. Validation of token is handled by
        # cosign and GitLab OIDC.
        raise InvalidInput unless /\A[\w-]+\.[\w-]+\.[\w-]+\z/.match?(id_token)
      end

      def validate_hash!(hash)
        raise InvalidInput unless /\A[A-Fa-f0-9]{64}\z/.match?(hash)
      end

      def validate_blob_name!(blob_name)
        Gitlab::PathTraversal.check_path_traversal!(blob_name)

        raise InvalidInput unless /\A[a-zA-Z0-9\.\-\_]+\z/.match?(blob_name)
      end

      def optional_arguments
        return [] if Rails.env.production?

        optional_arguments = []

        fulcio_url = ENV["COSIGN_FULCIO_URL"]
        rekor_url = ENV["COSIGN_REKOR_URL"]

        optional_arguments += ['--fulcio-url', fulcio_url] if fulcio_url
        optional_arguments += ['--rekor-url', rekor_url] if rekor_url

        optional_arguments
      end
    end
  end
end

Ci::Slsa::PublishProvenanceService.prepend_mod

# frozen_string_literal: true

module SupplyChain
  class ProvenancePublisher
    include Gitlab::Utils::StrongMemoize

    HASH_READ_CHUNK_SIZE = 1.megabyte

    Error = Class.new(StandardError)
    AttestationFailure = Class.new(Error)
    InvalidInput = Class.new(Error)

    def initialize(build)
      @build = build

      raise Error, "Job doesn't exist" unless @build

      @logger = Gitlab::AppJsonLogger

      @logger_base_args = {
        class: self.class.name,
        build_id: @build.id
      }
    end

    private

    def id_token
      @build.variables["SIGSTORE_ID_TOKEN"]&.value
    end
    strong_memoize_attr :id_token

    def log(**args)
      @logger.info(@logger_base_args.merge(args))
    end

    def predicate
      SupplyChain::Slsa::ProvenanceStatement::Predicate.from_build(@build).to_json
    end
    strong_memoize_attr :predicate

    def ci_server_url
      Gitlab.config.gitlab.url
    end

    def successful_attestation?(hash)
      existing_attestation = SupplyChain::Attestation.find_provenance(project: @build.project, subject_digest: hash)
      return true if existing_attestation&.success?

      existing_attestation&.destroy

      false
    end

    def cosign_attest_blob(blob_name:, hash:)
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

        if result.status.success?
          attestation = persist_attestation!(status: :success, subject_digest: hash,
            bundle_file: bundle_file)
        end
      end

      return attestation, result.duration if result.status.success?

      error = result.stderr
      raise AttestationFailure, "Attestation for #{hash} failed after #{result.duration}s: #{error}"
    end

    def persist_attestation!(status:, subject_digest:, bundle_file: nil)
      attestation = SupplyChain::Attestation.new do |att|
        att.subject_digest = subject_digest
        att.project = @build.project
        att.build = @build
        att.status = status
        att.expire_at = 2.years.from_now # TODO: adjust based on outcomes of ticket discussion.
        att.predicate_kind = :provenance
        att.predicate_type = SupplyChain::Slsa::ProvenanceStatement::PREDICATE_TYPE_V1
        att.file = bundle_file
      end

      attestation.save!

      attestation
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

# frozen_string_literal: true

module SupplyChain
  class ProvenancePublisher
    include Gitlab::Utils::StrongMemoize

    HASH_READ_CHUNK_SIZE = 1.megabyte
    COSIGN_KEY_PREFIX = 'cosign'
    COSIGN_PASSWORD_BYTES = 32
    COSIGN_CA_CERTIFICATE_FILE = 'ca.crt.pem'
    COSIGN_SIGNING_CONFIG_FILE = 'signing-config.json'
    COSIGN_TRUSTED_ROOT_FILE = 'trusted-root.json'
    LEAF_CERTIFICATE_FILE = 'leaf.crt.pem'

    Error = Class.new(StandardError)
    JwtGenerationError = Class.new(Error)
    AttestationFailure = Class.new(Error)
    InvalidInput = Class.new(Error)
    KeyImportFailure = Class.new(Error)
    SigningConfigFailure = Class.new(Error)
    TrustedRootFailure = Class.new(Error)
    LocalCaSigningError = Class.new(Error)

    LocalCaSigningMaterial = Struct.new(:key_path, :password, :certificate_path, :signing_certificate_id,
      keyword_init: true)

    def initialize(build)
      @build = build

      raise Error, "Job doesn't exist" unless @build

      @logger = Gitlab::AppJsonLogger

      @logger_base_args = {
        class: self.class.name,
        build_id: @build.id
      }

      raise JwtGenerationError, "Can't generate JWT token" unless id_token
    end

    private

    def id_token
      return unless @build.project

      sub_components = @build.project.ci_id_token_sub_claim_components.map(&:to_sym)
      Gitlab::Ci::JwtV2.for_build(@build, aud: "sigstore", sub_components: sub_components)
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

    def cosign_attest_blob(hash:, blob_name: nil)
      validate_id_token!(id_token)
      validate_hash!(hash)

      if blob_name
        validate_blob_name!(blob_name)
      else
        blob_name = hash
      end

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
          '--use-signing-config=false',
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

    def with_local_ca_signing_material
      Dir.mktmpdir('slsa-local-ca-') do |dir|
        yield prepare_local_ca_signing_material(dir)
      end
    end

    def prepare_local_ca_signing_material(dir)
      driver = SupplyChain::PostgresCaDriver.new(@build.project)
      leaf = driver.generate_leaf_certificate(ci_config_ref_uri: @build.pipeline.ci_config_ref_uri)

      certificate_path = File.join(dir, LEAF_CERTIFICATE_FILE)
      File.write(certificate_path, leaf.certificate.to_pem, perm: 0o600)
      imported = cosign_import_key_pair(key: leaf.key, dir: dir)

      LocalCaSigningMaterial.new(
        key_path: imported[:key_path],
        password: imported[:password],
        certificate_path: certificate_path,
        signing_certificate_id: driver.signing_certificate.id
      )
    rescue SupplyChain::RootCaDriver::Error => e
      raise LocalCaSigningError, "Unable to prepare local CA signing material: #{e.message}"
    end

    def cosign_import_key_pair(key:, dir:)
      validate_key_dir!(dir)

      password = SecureRandom.hex(COSIGN_PASSWORD_BYTES)
      key_prefix = File.join(dir, COSIGN_KEY_PREFIX)
      command = ['cosign', 'import-key-pair', '--yes', '--key', '/dev/stdin', '--output-key-prefix', key_prefix]

      result = Gitlab::Popen.popen_with_detail(command, nil, { 'COSIGN_PASSWORD' => password }) do |stdin|
        stdin.write(key.private_to_pem)
      end

      return { key_path: "#{key_prefix}.key", password: password } if result.status.success?

      raise KeyImportFailure, "Key import failed after #{result.duration}s: #{result.stderr}"
    end

    def cosign_create_signing_config(dir:)
      validate_key_dir!(dir)

      signing_config_path = File.join(dir, COSIGN_SIGNING_CONFIG_FILE)
      command = ['cosign', 'signing-config', 'create', '--out', signing_config_path]

      result = Gitlab::Popen.popen_with_detail(command)

      return signing_config_path if result.status.success?

      raise SigningConfigFailure, "Signing config creation failed after #{result.duration}s: #{result.stderr}"
    end

    def cosign_create_trusted_root(ca_certificate:, dir:)
      validate_key_dir!(dir)

      issuer = ci_server_url
      # cosign splits --fulcio on commas, so neither value may contain one.
      raise InvalidInput if dir.include?(',') || issuer.include?(',')
      raise InvalidInput unless ca_certificate.is_a?(OpenSSL::X509::Certificate)

      ca_path = File.join(dir, COSIGN_CA_CERTIFICATE_FILE)
      trusted_root_path = File.join(dir, COSIGN_TRUSTED_ROOT_FILE)
      File.write(ca_path, ca_certificate.to_pem, perm: 0o600)

      command = [
        'cosign', 'trusted-root', 'create',
        '--fulcio', "url=#{issuer},certificate-chain=#{ca_path}",
        '--no-default-fulcio', '--no-default-rekor', '--no-default-ctfe', '--no-default-tsa',
        '--out', trusted_root_path
      ]

      result = Gitlab::Popen.popen_with_detail(command)

      return trusted_root_path if result.status.success?

      raise TrustedRootFailure, "Trusted root creation failed after #{result.duration}s: #{result.stderr}"
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

    def persist_error_attestation(subject_digest:)
      persist_attestation!(status: :error, subject_digest: subject_digest)

    rescue StandardError => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, project_id: @build.project.id)

      nil
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

    def validate_key_dir!(dir)
      raise InvalidInput unless dir.is_a?(String)

      Gitlab::PathTraversal.check_path_traversal!(dir)

      raise InvalidInput unless Pathname.new(dir).absolute? && File.directory?(dir)
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

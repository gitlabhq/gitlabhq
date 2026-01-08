# frozen_string_literal: true

module Projects
  class AttestationsController < Projects::ApplicationController
    include SendFileUpload

    # Fulcio-assigned OID prefix for certificate extensions
    # See: https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md
    # and https://oid-base.com/get/1.3.6.1.4.1.57264.1
    FULCIO_OID_PREFIX = '1.3.6.1.4.1.57264.1.'

    # Maps OID suffixes to human-readable attribute names
    FULCIO_EXTENSION_MAP = {
      '8' => :issuer,
      '9' => :build_signer_uri,
      '10' => :build_signer_digest,
      '11' => :runner_environment,
      '12' => :source_repository_uri,
      '13' => :source_repository_digest,
      '14' => :source_repository_ref,
      '15' => :source_repository_identifier,
      '16' => :source_repository_owner_uri,
      '17' => :source_repository_owner_identifier,
      '18' => :build_config_uri,
      '19' => :build_config_digest,
      '20' => :build_trigger,
      '21' => :runner_invocation_uri,
      '22' => :source_repository_visibility
    }.freeze

    feature_category :artifact_security

    before_action :authorize_read_attestation!, only: [:index, :show, :download]
    before_action :check_feature_flag!, only: [:index, :show, :download]

    def index
      @project = project
      @attestations = SupplyChain::Attestation
        .for_project(project.id)
        .keyset_paginate(cursor: pagination_params[:cursor])
    end

    def show
      @project = project
      @attestation_iid_param = safe_params[:id]
      @attestation = attestation
      @subjects = parsed_metadata['subject'] || []
      @certificate = parsed_certificate_extensions
    end

    def download
      return render_404 unless attestation_file

      send_upload(attestation_file, attachment: attestation_file.filename)
    end

    private

    def attestation
      @attestation ||= SupplyChain::Attestation.find_by_project_id_and_iid(project.id, safe_params[:id])
    end

    def attestation_file
      attestation&.file
    end

    def authorize_read_attestation!
      access_denied! unless can?(current_user, :read_attestation, project)
    end

    def check_feature_flag!
      render_404 unless Feature.enabled?(:slsa_provenance_statement, project)
    end

    def clean_extension_value(value)
      # Remove ASN.1 type prefixes (dot followed by any character and optional whitespace)
      value.to_s.sub(/\A\.\S?\s*/, '')
    end

    def pagination_params
      params.permit(:cursor)
    end

    def parsed_attestation_file
      @parsed_attestation_file ||= begin
        if attestation && attestation_file
          Gitlab::Json.safe_parse(attestation_file.read)
        else
          {}
        end
      rescue JSON::ParserError => e
        Gitlab::AppJsonLogger.error(
          message: 'Failed to parse attestation file',
          error_class: e.class.name,
          error_message: e.message,
          attestation_id: attestation&.id,
          project_id: project.id,
          feature_category: 'artifact_security'
        )
        {}
      end
    end

    def parsed_metadata
      @parsed_metadata ||= begin
        if parsed_attestation_file.blank?
          {}
        else
          decoded = Base64.decode64(parsed_attestation_file.dig("dsseEnvelope", "payload"))
          Gitlab::Json.safe_parse(decoded)
        end
      rescue JSON::ParserError => e
        Gitlab::AppJsonLogger.error(
          message: 'Failed to parse attestation metadata',
          error_class: e.class.name,
          error_message: e.message,
          attestation_id: attestation&.id,
          project_id: project.id,
          feature_category: 'artifact_security'
        )
        {}
      end
    end

    def parsed_certificate
      return {} if parsed_attestation_file.blank?

      cert_data = parsed_attestation_file.dig("verificationMaterial", "certificate", "rawBytes")
      decoded_certificate = Base64.decode64(cert_data)
      OpenSSL::X509::Certificate.new(decoded_certificate)

    rescue OpenSSL::X509::CertificateError => e
      Gitlab::AppJsonLogger.error(
        message: 'Failed to parse attestation certificate',
        error_class: e.class.name,
        error_message: e.message,
        attestation_id: attestation&.id,
        project_id: project.id,
        feature_category: 'artifact_security'
      )
      {}
    end

    def parsed_certificate_extensions
      return {} if parsed_certificate.blank?

      extensions = {}

      # This is based on https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#extension-values
      parsed_certificate.extensions.each do |ext|
        next unless ext.oid.starts_with?(FULCIO_OID_PREFIX)

        cleaned_key = ext.oid.split('.').last

        next unless FULCIO_EXTENSION_MAP.key?(cleaned_key)

        cleaned_value = clean_extension_value(ext.value)

        extensions[FULCIO_EXTENSION_MAP[cleaned_key.to_s]] = cleaned_value
      end

      extensions
    end
  end
end

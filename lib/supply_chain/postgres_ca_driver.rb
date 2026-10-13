# frozen_string_literal: true

module SupplyChain
  class PostgresCaDriver < RootCaDriver
    def initialize(project)
      @project = project
    end

    # Set by fetch_ca/provision_ca! while RootCaDriver#ca_certificate resolves the CA.
    def signing_certificate
      return @signing_certificate if @signing_certificate

      ca_certificate

      @signing_certificate
    end

    private

    def fetch_ca
      certificate_record = find_active_certificate
      return unless certificate_record

      track_signing_certificate(certificate_record)
    end

    def provision_ca!
      ca_key = OpenSSL::PKey::EC.generate(EC_CURVE)
      ca_cert = build_ca_certificate(key: ca_key)
      ca_cert.sign(ca_key, digest)

      track_signing_certificate(store_certificate(key: ca_key, certificate: ca_cert))
    end

    def sign_with_ca(certificate)
      ca_key = OpenSSL::PKey.read(signing_certificate.private_key)
      certificate.sign(ca_key, digest)

      certificate
    end

    def track_signing_certificate(certificate_record)
      certificate = OpenSSL::X509::Certificate.new(certificate_record.certificate)
      @signing_certificate = (certificate_record if valid_for_leaf_certificate?(certificate))

      certificate
    end

    def store_certificate(key:, certificate:)
      SigningCertificate.transaction do
        existing_certificate = find_active_certificate

        if valid_certificate_record?(existing_certificate)
          existing_certificate
        elsif existing_certificate
          raise InvalidCaCertificate, 'an unusable active CA certificate already exists'
        else
          SigningCertificate.create!(
            project: @project,
            active: true,
            private_key: key.to_pem,
            certificate: certificate.to_pem
          )
        end
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => error
      raise error unless certificate_conflict?(error)

      find_active_certificate || raise
    end

    def valid_certificate_record?(certificate_record)
      return false unless certificate_record

      certificate = OpenSSL::X509::Certificate.new(certificate_record.certificate)

      valid_for_leaf_certificate?(certificate)
    end

    def certificate_conflict?(error)
      error.is_a?(ActiveRecord::RecordNotUnique) || error.record.errors.of_kind?(:active, :taken)
    end

    def find_active_certificate
      SigningCertificate.for_project(@project).with_active.first
    end
  end
end

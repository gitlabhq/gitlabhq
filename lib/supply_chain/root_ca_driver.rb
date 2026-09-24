# frozen_string_literal: true

module SupplyChain
  class RootCaDriver
    Error = Class.new(StandardError)
    InvalidInput = Class.new(Error)
    InvalidCaCertificate = Class.new(Error)

    EC_CURVE = 'prime256v1'
    DIGEST_ALGORITHM = 'SHA256'

    CA_VALIDITY = 10.years
    LEAF_VALIDITY = 5.years
    CLOCK_SKEW = 5.minutes

    CA_SUBJECT = [%w[CN ca], %w[DC gitlab]].freeze
    X509_VERSION_3 = 2

    FULCIO_ISSUER_OID = '1.3.6.1.4.1.57264.1.8'
    GENERAL_NAME_URI_TAG = 6

    LeafCertificate = Struct.new(:key, :certificate, keyword_init: true)

    def ca_certificate
      certificate = fetch_ca || provision_ca!
      return certificate if valid_for_leaf_certificate?(certificate)

      raise InvalidCaCertificate, 'active CA certificate expires before the leaf certificate'
    end

    def generate_leaf_certificate(ci_config_ref_uri:)
      raise InvalidInput, 'ci_config_ref_uri is required' if ci_config_ref_uri.blank?

      ca_cert = ca_certificate

      key = OpenSSL::PKey::EC.generate(EC_CURVE)
      certificate = build_certificate(key: key, validity: LEAF_VALIDITY)
      certificate.subject = OpenSSL::X509::Name.new([])
      certificate.issuer = ca_cert.subject

      factory = extension_factory(subject: certificate, issuer: ca_cert)
      certificate.add_extension(factory.create_extension('basicConstraints', 'CA:FALSE', true))
      certificate.add_extension(factory.create_extension('keyUsage', 'digitalSignature', true))
      certificate.add_extension(factory.create_extension('extendedKeyUsage', 'codeSigning'))
      certificate.add_extension(factory.create_extension('subjectKeyIdentifier', 'hash'))
      certificate.add_extension(factory.create_extension('authorityKeyIdentifier', 'keyid:always'))
      certificate.add_extension(subject_alt_name_extension(identity_uri(ci_config_ref_uri)))
      certificate.add_extension(fulcio_issuer_extension)

      sign_with_ca(certificate)

      LeafCertificate.new(key: key, certificate: certificate)
    end

    private

    def fetch_ca
      raise Gitlab::AbstractMethodError
    end

    def provision_ca!
      raise Gitlab::AbstractMethodError
    end

    def sign_with_ca(_certificate)
      raise Gitlab::AbstractMethodError
    end

    def build_ca_certificate(key:)
      name = OpenSSL::X509::Name.new(CA_SUBJECT)

      certificate = build_certificate(key: key, validity: CA_VALIDITY)
      certificate.subject = name
      certificate.issuer = name

      factory = extension_factory(subject: certificate, issuer: certificate)
      certificate.add_extension(factory.create_extension('basicConstraints', 'CA:TRUE', true))
      certificate.add_extension(factory.create_extension('keyUsage', 'keyCertSign,cRLSign', true))
      certificate.add_extension(factory.create_extension('subjectKeyIdentifier', 'hash'))

      certificate
    end

    def build_certificate(key:, validity:)
      certificate = OpenSSL::X509::Certificate.new
      certificate.version = X509_VERSION_3
      certificate.serial = random_serial
      certificate.not_before = CLOCK_SKEW.ago
      certificate.not_after = validity.from_now
      certificate.public_key = key

      certificate
    end

    def extension_factory(subject:, issuer:)
      factory = OpenSSL::X509::ExtensionFactory.new
      factory.subject_certificate = subject
      factory.issuer_certificate = issuer

      factory
    end

    def subject_alt_name_extension(uri)
      general_name = OpenSSL::ASN1::ASN1Data.new(uri, GENERAL_NAME_URI_TAG, :CONTEXT_SPECIFIC)
      value = OpenSSL::ASN1::Sequence.new([general_name])

      OpenSSL::X509::Extension.new('subjectAltName', value.to_der, true)
    end

    def fulcio_issuer_extension
      value = OpenSSL::ASN1::UTF8String.new(ci_server_url)

      OpenSSL::X509::Extension.new(FULCIO_ISSUER_OID, value.to_der, false)
    end

    def identity_uri(ci_config_ref_uri)
      Addressable::URI.parse("#{ci_server_protocol}://#{ci_config_ref_uri}").normalize.to_s
    end

    def valid_for_leaf_certificate?(certificate)
      certificate && certificate.not_after >= (LEAF_VALIDITY + CLOCK_SKEW).from_now
    end

    def ci_server_url
      Gitlab.config.gitlab.url
    end

    def ci_server_protocol
      Gitlab.config.gitlab.protocol
    end

    def digest
      OpenSSL::Digest.new(DIGEST_ALGORITHM)
    end

    def random_serial
      SecureRandom.random_number(1...(2**159))
    end
  end
end

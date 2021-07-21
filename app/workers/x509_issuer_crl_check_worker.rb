# frozen_string_literal: true

class X509IssuerCrlCheckWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :source_code_management
  urgency :low

  idempotent!
  worker_has_external_dependencies!

  attr_accessor :logger

  def perform
    @logger = Gitlab::GitLogger.build

    X509Issuer.all.find_each do |issuer|
      with_context(related_class: X509IssuerCrlCheckWorker) do
        update_certificates(issuer)
      end
    end
  end

  private

  def update_certificates(issuer)
    crl = download_crl(issuer)
    return unless crl

    serials = X509Certificate.serial_numbers(issuer)
    return if serials.empty?

    revoked_serials = serials & crl.revoked.map(&:serial).map(&:to_i)

    revoked_serials.each_slice(1000) do |batch|
      certs = issuer.x509_certificates.where(serial_number: batch, certificate_status: :good) # rubocop: disable CodeReuse/ActiveRecord

      certs.find_each do |cert|
        logger.info(message: "Certificate revoked",
          id: cert.id,
          email: cert.email,
          subject: cert.subject,
          serial_number: cert.serial_number,
          issuer: cert.x509_issuer.id,
          issuer_subject: cert.x509_issuer.subject,
          issuer_crl_url: cert.x509_issuer.crl_url)
      end

      certs.update_all(certificate_status: :revoked)
    end
  end

  def download_crl(issuer)
    response = Gitlab::HTTP.try_get(issuer.crl_url)

    if response&.code == 200
      OpenSSL::X509::CRL.new(response.body)
    else
      logger.warn(message: "Failed to download certificate revocation list",
        issuer: issuer.id,
        issuer_subject: issuer.subject,
        issuer_crl_url: issuer.crl_url)

      nil
    end

  rescue OpenSSL::X509::CRLError
    logger.warn(message: "Failed to parse certificate revocation list",
      issuer: issuer.id,
      issuer_subject: issuer.subject,
      issuer_crl_url: issuer.crl_url)

    nil
  end
end

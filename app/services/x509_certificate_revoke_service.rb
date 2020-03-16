# frozen_string_literal: true

class X509CertificateRevokeService
  def execute(certificate)
    return unless certificate.revoked?

    certificate.x509_commit_signatures.update_all(verification_status: :unverified)
  end
end

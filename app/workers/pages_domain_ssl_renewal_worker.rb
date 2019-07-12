# frozen_string_literal: true

class PagesDomainSslRenewalWorker
  include ApplicationWorker

  def perform(domain_id)
    domain = PagesDomain.find_by_id(domain_id)
    return unless domain&.enabled?
    return unless ::Gitlab::LetsEncrypt.enabled?

    ::PagesDomains::ObtainLetsEncryptCertificateService.new(domain).execute
  end
end

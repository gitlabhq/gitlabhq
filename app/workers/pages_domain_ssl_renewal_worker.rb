# frozen_string_literal: true

class PagesDomainSslRenewalWorker
  include ApplicationWorker

  def perform(domain_id)
    return unless ::Gitlab::LetsEncrypt::Client.new.enabled?

    domain = PagesDomain.find_by_id(domain_id)

    return unless domain

    ::PagesDomains::ObtainLetsEncryptCertificateService.new(domain).execute
  end
end

# frozen_string_literal: true

class PagesDomainSslRenewalWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :pages
  tags :requires_disk_io, :exclude_from_kubernetes

  def perform(domain_id)
    domain = PagesDomain.find_by_id(domain_id)
    return unless domain&.enabled?
    return unless ::Gitlab::LetsEncrypt.enabled?

    ::PagesDomains::ObtainLetsEncryptCertificateService.new(domain).execute
  end
end

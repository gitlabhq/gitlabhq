# frozen_string_literal: true

class PagesDomainSslRenewalWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobChildWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :pages

  def perform(domain_id)
    domain = PagesDomain.find_by_id(domain_id)
    return unless domain&.enabled?
    return unless ::Gitlab::LetsEncrypt.enabled?

    ::Pages::Domains::ObtainLetsEncryptCertificateService.new(domain).execute
  end
end

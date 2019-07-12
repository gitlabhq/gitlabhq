# frozen_string_literal: true

class PagesDomainSslRenewalCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless ::Gitlab::LetsEncrypt.enabled?

    PagesDomain.need_auto_ssl_renewal.find_each do |domain|
      PagesDomainSslRenewalWorker.perform_async(domain.id)
    end
  end
end

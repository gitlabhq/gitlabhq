# frozen_string_literal: true

class PagesDomainSslRenewalCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    PagesDomain.need_auto_ssl_renewal.find_each do |domain|
      next unless ::Gitlab::LetsEncrypt.enabled?(domain)

      PagesDomainSslRenewalWorker.perform_async(domain.id)
    end
  end
end

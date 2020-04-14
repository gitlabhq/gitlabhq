# frozen_string_literal: true

module PagesDomains
  class RetryAcmeOrderService
    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      updated = pages_domain.with_lock do
        next unless pages_domain.auto_ssl_enabled && pages_domain.auto_ssl_failed

        pages_domain.update!(auto_ssl_failed: false)
      end

      PagesDomainSslRenewalWorker.perform_async(pages_domain.id) if updated
    end
  end
end

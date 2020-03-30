# frozen_string_literal: true

class PagesDomainSslRenewalCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :pages

  def perform
    return unless ::Gitlab::LetsEncrypt.enabled?

    PagesDomain.need_auto_ssl_renewal.with_logging_info.find_each do |domain|
      # Ideally that should be handled in PagesDomain.need_auto_ssl_renewal scope
      # but it's hard to make scope work with feature flags
      # once we remove feature flag we can modify scope to implement this behaviour
      next if Feature.enabled?(:pages_letsencrypt_errors, domain.project) && domain.auto_ssl_failed

      with_context(project: domain.project) do
        PagesDomainSslRenewalWorker.perform_async(domain.id)
      end
    end
  end
end

# frozen_string_literal: true

class PagesDomainSslRenewalCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :pages

  def perform
    return unless ::Gitlab::LetsEncrypt.enabled?

    PagesDomain.need_auto_ssl_renewal.with_logging_info.find_each do |domain|
      with_context(project: domain.project) do
        PagesDomainSslRenewalWorker.perform_async(domain.id)
      end
    end
  end
end

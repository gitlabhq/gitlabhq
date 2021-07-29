# frozen_string_literal: true

class PagesDomainSslRenewalCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue

  feature_category :pages
  worker_resource_boundary :cpu

  def perform
    return unless ::Gitlab::LetsEncrypt.enabled?

    PagesDomain.need_auto_ssl_renewal.with_logging_info.find_each do |domain|
      with_context(project: domain.project) do
        PagesDomainSslRenewalWorker.perform_async(domain.id)
      end
    end
  end
end

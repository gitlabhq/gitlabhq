# frozen_string_literal: true

class PagesDomainVerificationCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue

  feature_category :pages
  worker_resource_boundary :cpu

  def perform
    return if Gitlab::Database.read_only?

    PagesDomain.needs_verification.with_logging_info.find_each do |domain|
      with_context(project: domain.project) do
        PagesDomainVerificationWorker.perform_async(domain.id)
      end
    end
  end
end

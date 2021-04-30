# frozen_string_literal: true

class PagesDomainVerificationCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :pages

  def perform
    return if Gitlab::Database.read_only?

    PagesDomain.needs_verification.with_logging_info.find_each do |domain|
      with_context(project: domain.project) do
        PagesDomainVerificationWorker.perform_async(domain.id)
      end
    end
  end
end

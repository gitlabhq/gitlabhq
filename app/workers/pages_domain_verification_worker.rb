# frozen_string_literal: true

class PagesDomainVerificationWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobChildWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :pages

  def perform(domain_id)
    return if Gitlab::Database.read_only?

    domain = PagesDomain.find_by_id(domain_id)

    return unless domain

    VerifyPagesDomainService.new(domain).execute
  end
end

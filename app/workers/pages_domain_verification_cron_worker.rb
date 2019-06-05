# frozen_string_literal: true

class PagesDomainVerificationCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return if Gitlab::Database.read_only?

    PagesDomain.needs_verification.find_each do |domain|
      PagesDomainVerificationWorker.perform_async(domain.id)
    end
  end
end

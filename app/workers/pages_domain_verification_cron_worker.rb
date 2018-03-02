class PagesDomainVerificationCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    PagesDomain.needs_verification.find_each do |domain|
      PagesDomainVerificationWorker.perform_async(domain.id)
    end
  end
end

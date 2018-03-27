class PagesDomainVerificationWorker
  include ApplicationWorker

  def perform(domain_id)
    domain = PagesDomain.find_by(id: domain_id)

    return unless domain

    VerifyPagesDomainService.new(domain).execute
  end
end

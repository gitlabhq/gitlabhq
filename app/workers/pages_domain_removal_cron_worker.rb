# frozen_string_literal: true

class PagesDomainRemovalCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :pages
  worker_resource_boundary :cpu

  def perform
    PagesDomain.for_removal.with_logging_info.find_each do |domain|
      with_context(project: domain.project) { domain.destroy! }
    rescue => e
      Gitlab::ErrorTracking.track_exception(e)
    end
  end
end

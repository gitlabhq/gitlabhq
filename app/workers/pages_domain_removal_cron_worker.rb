# frozen_string_literal: true

class PagesDomainRemovalCronWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :pages
  worker_resource_boundary :cpu

  def perform
    PagesDomain.for_removal.find_each do |domain|
      domain.destroy!
    rescue => e
      Gitlab::ErrorTracking.track_exception(e)
    end
  end
end

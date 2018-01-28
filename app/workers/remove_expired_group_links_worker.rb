class RemoveExpiredGroupLinksWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    ProjectGroupLink.expired.destroy_all
  end
end

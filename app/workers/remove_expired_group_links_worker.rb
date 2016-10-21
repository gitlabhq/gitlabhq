class RemoveExpiredGroupLinksWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    ProjectGroupLink.expired.destroy_all
  end
end

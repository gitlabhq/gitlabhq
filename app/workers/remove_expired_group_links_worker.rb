class RemoveExpiredGroupLinksWorker
  include Sidekiq::Worker

  def perform
    ProjectGroupLink.expired.destroy_all
  end
end

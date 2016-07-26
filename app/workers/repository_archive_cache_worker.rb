class RepositoryArchiveCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    RepositoryArchiveCleanUpService.new.execute
  end
end

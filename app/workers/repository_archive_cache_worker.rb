class RepositoryArchiveCacheWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    RepositoryArchiveCleanUpService.new.execute
  end
end

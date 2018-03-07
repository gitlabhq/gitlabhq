class RepositoryArchiveCacheWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    RepositoryArchiveCleanUpService.new.execute
  end
end

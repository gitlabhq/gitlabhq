class RepositoryArchiveCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Repository.clean_old_archives
  end
end

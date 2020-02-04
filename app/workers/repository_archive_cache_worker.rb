# frozen_string_literal: true

class RepositoryArchiveCacheWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    RepositoryArchiveCleanUpService.new.execute
  end
end

# frozen_string_literal: true

class PartitionCreationWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :database
  idempotent!

  def perform
    # This worker has been removed in favor of Database::PartitionManagementWorker
    Database::PartitionManagementWorker.new.perform
  end
end

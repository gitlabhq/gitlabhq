# frozen_string_literal: true

class PartitionCreationWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :database
  idempotent!

  def perform
    Gitlab::AppLogger.info("Checking state of dynamic postgres partitions")

    Gitlab::Database::Partitioning::PartitionCreator.new.create_partitions
  end
end

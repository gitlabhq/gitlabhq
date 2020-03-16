# frozen_string_literal: true

class RemoveUnreferencedLfsObjectsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :git_lfs

  def perform
    LfsObject.destroy_unreferenced
  end
end

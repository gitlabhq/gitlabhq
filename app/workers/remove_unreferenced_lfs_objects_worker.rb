# frozen_string_literal: true

class RemoveUnreferencedLfsObjectsWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    LfsObject.destroy_unreferenced
  end
end

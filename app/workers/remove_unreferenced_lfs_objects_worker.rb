class RemoveUnreferencedLfsObjectsWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    LfsObject.destroy_unreferenced
  end
end

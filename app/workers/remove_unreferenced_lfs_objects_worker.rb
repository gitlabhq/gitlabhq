class RemoveUnreferencedLfsObjectsWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    LfsObject.destroy_unreferenced
  end
end

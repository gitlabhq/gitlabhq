class UpdateAllMirrorsWorker
  include Sidekiq::Worker

  def perform
    Project.mirror.each(&:update_mirror)
  end
end

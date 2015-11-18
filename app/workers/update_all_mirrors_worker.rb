class UpdateAllMirrorsWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly }

  def perform
    Project.mirror.each(&:update_mirror)
  end
end

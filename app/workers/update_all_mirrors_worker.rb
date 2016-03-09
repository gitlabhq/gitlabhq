class UpdateAllMirrorsWorker
  include Sidekiq::Worker

  def perform
    fail_stuck_mirrors!

    Project.mirror.each(&:update_mirror)
  end

  def fail_stuck_mirrors!
    stuck = Project.mirror.
      with_import_status(:started).
      where('mirror_last_update_at < ?', 1.day.ago)

    stuck.find_each(batch_size: 50) do |project|
      project.mark_import_as_failed('The mirror update took too long to complete.')
    end
  end
end

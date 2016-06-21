class UpdateAllMirrorsWorker
  include Sidekiq::Worker

  LEASE_TIMEOUT = 3600

  def perform
    return unless try_obtain_lease

    fail_stuck_mirrors!

    Project.mirror.find_each(batch_size: 200) do |project|
      project.update_mirror(delay: rand(30.minutes))
    end
  end

  def fail_stuck_mirrors!
    stuck = Project.mirror.
      with_import_status(:started).
      where('mirror_last_update_at < ?', 1.day.ago)

    stuck.find_each(batch_size: 50) do |project|
      project.mark_import_as_failed('The mirror update took too long to complete.')
    end
  end

  private

  def try_obtain_lease
    # Using 30 minutes timeout based on the 95th percent of timings (currently max of 10 minutes)
    lease = ::Gitlab::ExclusiveLease.new("update_all_mirrors", timeout: LEASE_TIMEOUT)
    lease.try_obtain
  end
end

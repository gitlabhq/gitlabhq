class UpdateAllMirrorsWorker
  include Sidekiq::Worker
  include CronjobQueue

  LEASE_TIMEOUT = 5.minutes
  LEASE_KEY = 'update_all_mirrors'.freeze

  def perform
    # This worker requires updating the database state, which we can't
    # do on a Geo secondary
    return if Gitlab::Geo.secondary?

    lease_uuid = try_obtain_lease
    return unless lease_uuid

    fail_stuck_mirrors!

    return if Gitlab::Mirror.max_mirror_capacity_reached?
    Project.mirrors_to_sync.find_each(batch_size: 200, &:import_schedule)

    cancel_lease(lease_uuid)
  end

  def fail_stuck_mirrors!
    Project.stuck_mirrors.find_each(batch_size: 50) do |project|
      project.mark_import_as_failed('The mirror update took too long to complete.')
    end
  end

  private

  def try_obtain_lease
    ::Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain
  end

  def cancel_lease(uuid)
    ::Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
  end
end

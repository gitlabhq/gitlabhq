class UpdateAllMirrorsWorker
  include Sidekiq::Worker
  include CronjobQueue

  LEASE_TIMEOUT = 840

  def perform
    return unless try_obtain_lease

    fail_stuck_mirrors!

    mirrors_to_sync.find_each(batch_size: 200) do |project|
      RepositoryUpdateMirrorDispatchWorker.perform_in(rand((project.sync_time / 2).minutes), project.id)
    end
  end

  def fail_stuck_mirrors!
    stuck = Project.mirror
      .with_import_status(:started)
      .where('mirror_last_update_at < ?', 2.hours.ago)

    stuck.find_each(batch_size: 50) do |project|
      project.mark_import_as_failed('The mirror update took too long to complete.')
    end
  end

  private

  def mirrors_to_sync
    Project.mirror.where("mirror_last_successful_update_at + #{Gitlab::Database.minute_interval('sync_time')} <= ? OR sync_time IN (?)", DateTime.now, Gitlab::Mirror.sync_times)
  end

  def try_obtain_lease
    lease = ::Gitlab::ExclusiveLease.new("update_all_mirrors", timeout: LEASE_TIMEOUT)
    lease.try_obtain
  end
end

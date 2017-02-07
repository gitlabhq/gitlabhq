class UpdateAllRemoteMirrorsWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    fail_stuck_mirrors!

    remote_mirrors_to_sync.find_each(batch_size: 50).each(&:sync)
  end

  def fail_stuck_mirrors!
    RemoteMirror.stuck.find_each(batch_size: 50) do |remote_mirror|
      remote_mirror.mark_as_failed('The mirror update took too long to complete.')
    end
  end

  private

  def remote_mirrors_to_sync
    RemoteMirror.where("last_successful_update_at + #{Gitlab::Database.minute_interval('sync_time')} <= ? OR sync_time IN (?)", DateTime.now, Gitlab::Mirror.sync_times)
  end
end

class UpdateAllRemoteMirrorsWorker
  include Sidekiq::Worker

  def perform
    fail_stuck_mirrors!

    RemoteMirror.find_each(batch_size: 50).each(&:sync)
  end

  def fail_stuck_mirrors!
    RemoteMirror.stuck.find_each(batch_size: 50) do |remote_mirror|
      remote_mirror.mark_as_failed('The mirror update took too long to complete.')
    end
  end
end

class AuthorizedProjectsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  LEASE_TIMEOUT = 1.minute.to_i

  def self.bulk_perform_async(args_list)
    Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
  end

  def perform(user_id)
    user = User.find_by(id: user_id)

    refresh(user) if user
  end

  def refresh(user)
    lease_key = "refresh_authorized_projects:#{user.id}"
    lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)

    until uuid = lease.try_obtain
      # Keep trying until we obtain the lease. If we don't do so we may end up
      # not updating the list of authorized projects properly. To prevent
      # hammering Redis too much we'll wait for a bit between retries.
      sleep(1)
    end

    begin
      user.refresh_authorized_projects
    ensure
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end
  end
end

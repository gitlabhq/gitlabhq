module ExclusiveLeaseGuard
  extend ActiveSupport::Concern

  def lease_key
    @lease_key ||= self.class.name.underscore
  end

  def try_obtain_lease
    lease = exclusive_lease.try_obtain

    unless lease
      log_error('Cannot obtain an exclusive lease. There must be another worker already in execution.')
      return
    end

    begin
      yield lease
    ensure
      release_lease(lease)
    end
  end

  def exclusive_lease
    @lease ||= Gitlab::ExclusiveLease.new(lease_key, timeout: lease_timeout)
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end
end

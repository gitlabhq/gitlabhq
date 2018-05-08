#
# Concern that helps with getting an exclusive lease for running a block
# of code.
#
# `#try_obtain_lease` takes a block which will be run if it was able to
# obtain  the lease. Implement `#lease_timeout` to configure the timeout
# for the exclusive lease. Optionally override `#lease_key` to set the
# lease key, it defaults to the class name with underscores.
#
module ExclusiveLeaseGuard
  extend ActiveSupport::Concern

  def try_obtain_lease
    lease = exclusive_lease.try_obtain

    unless lease
      log_error('Cannot obtain an exclusive lease. There must be another instance already in execution.')
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

  def lease_key
    @lease_key ||= self.class.name.underscore
  end

  def lease_timeout
    raise NotImplementedError,
      "#{self.class.name} does not implement #{__method__}"
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end

  def renew_lease!
    exclusive_lease.renew
  end

  def log_error(message, extra_args = {})
    logger.error(message)
  end
end

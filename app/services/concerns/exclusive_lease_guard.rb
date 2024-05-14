# frozen_string_literal: true

#
# Concern that helps with getting an exclusive lease for running a block
# of code.
#
# `#try_obtain_lease` takes a block which will be run if it was able to
# obtain  the lease. Implement `#lease_timeout` to configure the timeout
# for the exclusive lease.
#
# Optionally override `#lease_key` to set the
# lease key, it defaults to the class name with underscores.
#
# Optionally override `#lease_release?` to prevent the job to
# be re-executed more often than LEASE_TIMEOUT.
#
module ExclusiveLeaseGuard
  extend ActiveSupport::Concern

  def try_obtain_lease
    lease = exclusive_lease.try_obtain

    Gitlab::Instrumentation::ExclusiveLock.increment_requested_count

    unless lease
      log_lease_taken
      return
    end

    begin
      lease_start_time = Time.current
      yield lease
    ensure
      Gitlab::Instrumentation::ExclusiveLock.add_hold_duration(Time.current - lease_start_time)
      release_lease(lease) if lease_release?
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

  def lease_release?
    true
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end

  def renew_lease!
    exclusive_lease.renew
  end

  def log_lease_taken
    logger = Gitlab::AppJsonLogger
    args = { message: lease_taken_message, lease_key: lease_key, class_name: self.class.name, lease_timeout: lease_timeout }

    case lease_taken_log_level
    when :debug then logger.debug(args)
    when :info  then logger.info(args)
    when :warn  then logger.warn(args)
    else             logger.error(args)
    end
  end

  def lease_taken_message
    "Cannot obtain an exclusive lease. There must be another instance already in execution."
  end

  def lease_taken_log_level
    :error
  end
end

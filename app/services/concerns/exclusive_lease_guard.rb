# frozen_string_literal: true

#
# Concern that helps with getting an exclusive lease for running a block
# of code. There are flavors:
#  - `#try_obtain_lease`
#  - `#try_obtain_lease_for`
#
# `#try_obtain_lease` takes a block which will be run if it was able to
# obtain  the lease. Implement `#lease_timeout` to configure the timeout
# for the exclusive lease. Optionally override `#lease_key` to set the
# lease key, it defaults to the class name with underscores.
#
# `#try_obtain_lease_for` does about the same, but takes an additional
# `id` parameter. This `id` is passed to `#lease_key_for`.
#
module ExclusiveLeaseGuard
  extend ActiveSupport::Concern

  LeaseNotObtained = Class.new(StandardError)

  def try_obtain_lease(&block)
    try_obtain_lease_do(exclusive_lease, &block)
  end

  def try_obtain_lease_for(id, &block)
    try_obtain_lease_do(exclusive_lease_for(id), &block)
  end

  def try_obtain_lease_do(lease, &block)
    uuid = lease.try_obtain

    raise LeaseNotObtained unless uuid

    begin
      yield uuid
    ensure
      release_lease(uuid)
    end
  end

  def exclusive_lease
    @lease ||= Gitlab::ExclusiveLease.new(lease_key, timeout: lease_timeout)
  end

  def lease_key
    @lease_key ||= self.class.name.underscore
  end

  def exclusive_lease_for(id)
    Gitlab::ExclusiveLease.new(lease_key_for(id), timeout: lease_timeout)
  end

  def lease_key_for(id)
    self.class.name.underscore.concat(":{#id}")
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
end

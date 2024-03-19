# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes # rubocop:disable Gitlab/NamespacedClass -- We want this to be top level due to scope of use and no namespace due to ease of calling
  # watch background jobs need to reset on each job if using
  attribute :organization, :lock_organization

  def organization=(value)
    # The lock allows us to handle the case where we set organization, but it was nil and to honor that as a lock event
    # We also, currently, want to have this only set one time per thread.
    # This fits the request/response cycle, but of course for rake tasks/background jobs that use the same thread,
    # we will need to reset as the first step in execution with Current.reset..if used at those layers.
    if lock_organization
      message = 'Current.organization has already been set in the current thread and should not be set again.'
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(message))

      return # when outside of dev/test
    end

    self.lock_organization = true

    super(value)
  end

  private

  # No unlock.
  def lock_organization=(lock)
    lock_organization || super(lock)
  end
end

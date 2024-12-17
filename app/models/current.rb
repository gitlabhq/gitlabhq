# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass -- We want this to be top level due to scope of use and no namespace due to ease of calling
class Current < ActiveSupport::CurrentAttributes
  class OrganizationNotAssignedError < RuntimeError
    def message
      'Assign an organization to Current.organization before calling it.'
    end
  end

  class OrganizationAlreadyAssignedError < RuntimeError
    def message
      'Current.organization has already been set in the current thread and should not be set again.'
    end
  end

  # watch background jobs need to reset on each job if using
  attribute :organization, :organization_assigned
  attribute :token_info

  def organization=(value)
    # We want to explicitly allow only one organization assignment per thread
    # This fits the request/response cycle, but of course for rake tasks/background jobs that use the same thread,
    # we will need to reset as the first step in execution with Current.reset..if used at those layers.
    if organization_assigned
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(OrganizationAlreadyAssignedError.new)

      return # when outside of dev/test
    end

    self.organization_assigned = true

    Gitlab::ApplicationContext.push(organization: value)

    super(value)
  end

  def organization
    unless organization_assigned
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(OrganizationNotAssignedError.new)
    end

    Gitlab::Organizations::FallbackOrganizationTracker.trigger

    super
  end

  def organization_id
    organization&.id
  end

  private

  # Do not allow to reset this
  def organization_assigned=(value)
    organization_assigned || super(value)
  end
end
# rubocop:enable Gitlab/NamespacedClass

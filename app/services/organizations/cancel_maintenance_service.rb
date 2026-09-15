# frozen_string_literal: true

module Organizations
  class CancelMaintenanceService < BaseMaintenanceTransitionService
    def execute
      return success if organization.active?
      return error(_('Organization is not initializing maintenance')) unless organization.maintenance_initialization?

      # Re-check under a row lock so the guard and transition are atomic against
      # concurrent maintenance transitions on the same organization.
      organization.with_lock { cancel_organization_maintenance }
    end

    private

    def cancel_organization_maintenance
      return success if organization.active?
      return error(_('Organization is not initializing maintenance')) unless organization.maintenance_initialization?

      organization.cancel_maintenance

      return transition_failed(_('Could not cancel maintenance')) unless organization.active?

      log_event('Organization maintenance cancelled')

      success
    end
  end
end

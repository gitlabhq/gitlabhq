# frozen_string_literal: true

module Organizations
  class ConfirmMaintenanceService < BaseMaintenanceTransitionService
    def execute
      return success if organization.maintenance?
      return error(_('Organization is not initializing maintenance')) unless organization.maintenance_initialization?
      return error(_('Organization is not ready for maintenance'), reason: :not_ready) unless readiness.ready?

      # Re-check under a row lock so the guard and transition are atomic against
      # concurrent maintenance transitions on the same organization.
      organization.with_lock { confirm_organization_maintenance }
    end

    private

    def confirm_organization_maintenance
      return success if organization.maintenance?
      return error(_('Organization is not initializing maintenance')) unless organization.maintenance_initialization?

      organization.confirm_maintenance

      return transition_failed(_('Could not confirm maintenance')) unless organization.maintenance?

      log_event('Organization maintenance confirmed')

      success
    end

    def readiness
      ::Gitlab::Organizations::MaintenanceReadiness.new(organization)
    end
  end
end

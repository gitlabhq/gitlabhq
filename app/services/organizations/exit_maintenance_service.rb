# frozen_string_literal: true

module Organizations
  class ExitMaintenanceService < BaseMaintenanceTransitionService
    def execute
      return success if organization.active?
      return error(_('Organization is not in maintenance')) unless organization.maintenance?

      # Re-check under a row lock so the guard and transition are atomic against
      # concurrent maintenance transitions on the same organization.
      organization.with_lock { exit_organization_maintenance }
    end

    private

    def exit_organization_maintenance
      return success if organization.active?
      return error(_('Organization is not in maintenance')) unless organization.maintenance?

      organization.exit_maintenance

      return transition_failed(_('Could not exit maintenance')) unless organization.active?

      log_event('Organization maintenance exited')

      success
    end
  end
end

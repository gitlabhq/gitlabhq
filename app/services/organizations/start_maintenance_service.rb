# frozen_string_literal: true

module Organizations
  class StartMaintenanceService < BaseMaintenanceTransitionService
    def initialize(organization, maintenance_reason:)
      super(organization)
      @maintenance_reason = maintenance_reason
    end

    def execute
      return success if organization.maintenance_initialization?
      return error(_('Organization is not active')) unless organization.active?

      # Re-check under a row lock so the guard and transition are atomic against
      # concurrent maintenance transitions on the same organization.
      organization.with_lock { start_organization_maintenance }
    end

    private

    attr_reader :maintenance_reason

    def start_organization_maintenance
      return success if organization.maintenance_initialization?
      return error(_('Organization is not active')) unless organization.active?

      organization.start_maintenance(maintenance_reason: maintenance_reason)

      return transition_failed(_('Could not start maintenance')) unless organization.maintenance_initialization?

      log_event('Organization maintenance started')

      success
    end
  end
end

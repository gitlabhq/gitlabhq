# frozen_string_literal: true

# Blocks all requests, including reads, when the current organization is in
# maintenance mode. HTTP verb is an unreliable proxy for "no write" (some GETs
# perform writes), so the initial iteration denies every request.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/607966.
#
# Enforcement gates on the single `Organizations::Organization#maintenance?`
# predicate and is wrapped in the `organization_maintenance_enforcement` feature
# flag, so it ships dark and is a complete no-op when the flag is disabled.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/603377.
module EnforcesOrganizationMaintenanceMode
  extend ActiveSupport::Concern

  private

  def enforce_organization_maintenance_mode
    return unless organization_maintenance_mode?

    handle_organization_maintenance_mode_error
  end

  def organization_maintenance_mode?
    organization = ::Current.organization
    return false unless organization

    organization.maintenance_enforced?
  end

  def handle_organization_maintenance_mode_error
    if maintenance_mode_json_request?
      render_maintenance_mode_json_error
    else
      render_maintenance_mode_html_error
    end
  end

  # Named distinctly from ApplicationController#json_request? (which checks only
  # request.format.json?) so the XHR branch is not shadowed away by Ruby's
  # method resolution when this concern is included in ApplicationController.
  def maintenance_mode_json_request?
    request.format.json? || request.xhr?
  end

  def render_maintenance_mode_json_error
    organization = ::Current.organization

    status =
      if organization.maintenance_time_bounded?
        response.headers['Retry-After'] = Organizations::Organization::MAINTENANCE_MODE_RETRY_AFTER_SECONDS.to_s
        :service_unavailable
      else
        :forbidden
      end

    render json: { message: organization.maintenance_message }, status: status
  end

  # Renders a full error page rather than flash + redirect_back: with GETs also
  # blocked, any redirect target would itself be intercepted and loop.
  def render_maintenance_mode_html_error
    organization = ::Current.organization

    if organization.maintenance_time_bounded?
      response.headers['Retry-After'] = Organizations::Organization::MAINTENANCE_MODE_RETRY_AFTER_SECONDS.to_s
      render_503(organization.maintenance_message)
    else
      access_denied!(organization.maintenance_message)
    end
  end
end

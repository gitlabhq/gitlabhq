# frozen_string_literal: true

# Blocks write requests (POST/PATCH/PUT/DELETE) when the current organization is
# in read-only mode. Reads always pass through.
#
# Enforcement gates on the single `Organizations::Organization#read_only?`
# predicate and is wrapped in the `organization_read_only_enforcement` feature
# flag, so it ships dark and is a complete no-op when the flag is disabled.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/603377.
module EnforcesReadOnlyOrganization
  extend ActiveSupport::Concern

  WRITE_METHODS = %w[POST PATCH PUT DELETE].to_set.freeze

  private

  def enforce_read_only_organization
    return unless write_request?
    return unless organization_read_only?

    handle_read_only_organization_error
  end

  def organization_read_only?
    organization = ::Current.organization
    return false unless organization&.read_only?

    Feature.enabled?(:organization_read_only_enforcement, organization)
  end

  def write_request?
    WRITE_METHODS.include?(request.request_method)
  end

  def handle_read_only_organization_error
    if read_only_json_request?
      render_read_only_json_error
    else
      redirect_read_only_html_error
    end
  end

  # Named distinctly from ApplicationController#json_request? (which checks only
  # request.format.json?) so the XHR branch is not shadowed away by Ruby's
  # method resolution when this concern is included in ApplicationController.
  def read_only_json_request?
    request.format.json? || request.xhr?
  end

  def render_read_only_json_error
    time_bounded = ::Current.organization.read_only_time_bounded?

    status =
      if time_bounded
        response.headers['Retry-After'] = '60'
        :service_unavailable
      else
        :forbidden
      end

    render json: { message: read_only_organization_error_message(time_bounded) }, status: status
  end

  def redirect_read_only_html_error
    flash[:alert] = read_only_organization_error_message(::Current.organization.read_only_time_bounded?)
    redirect_back(fallback_location: root_path)
  end

  def read_only_organization_error_message(time_bounded)
    if time_bounded
      _('This organization is currently in read-only mode. Write operations are temporarily disabled.')
    else
      _('This organization is currently in read-only mode. Write operations are disabled.')
    end
  end
end

# frozen_string_literal: true

class Dashboard::ApplicationController < ApplicationController
  include ControllerWithCrossProjectAccessCheck
  include RecordUserLastActivity
  include SignInDashboardUxSli

  layout 'dashboard'

  requires_cross_project_access

  before_action :redirect_org_scoped_to_global
  after_action :observe_sign_in_dashboard_ux_sli

  private

  # Your Work dashboards are only org-scoped for isolated organizations. When
  # reached via an /o/:organization_path URL without an isolated data context,
  # redirect to the equivalent global path so the canonical URL is used.
  #
  # The global path is derived from the request's own path by stripping the
  # leading /o/:organization_path segment, keeping the query string verbatim.
  # This never emits an off-host URL, and avoids url_for(params...) - which the
  # Cop/SafeParams cop forbids and which #safe_params can't satisfy here, since
  # some dashboard controllers (e.g. GroupTree) override it to drop routing keys.
  def redirect_org_scoped_to_global
    return unless Gitlab::Routing::OrganizationsHelper.organization_scoped_route?(request.path)
    return if ::Current.data_context.type == :organization

    global_path = request.path.sub(%r{\A/o/[^/]+}, '')
    global_path += "?#{request.query_string}" if request.query_string.present?

    redirect_to global_path
  end

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end

Dashboard::ApplicationController.prepend_mod

# frozen_string_literal: true

# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  include EnforcesAdminAuthentication
  include EnforcesStepUpAuthentication

  layout 'admin'

  private

  # The organization the admin area operates on. The instance admin area operates on the
  # single self-managed organization. Controllers should use this instead of
  # Current.organization so organization resolution stays in one overridable place.
  def admin_current_organization
    return Current.organization if Current.organization_assigned

    # rubocop:disable Gitlab/PreventOrganizationFirst -- Self-managed instances have a single organization
    Organizations::Organization.first
    # rubocop:enable Gitlab/PreventOrganizationFirst
  end
end

Admin::ApplicationController.prepend_mod_with('Admin::ApplicationController')

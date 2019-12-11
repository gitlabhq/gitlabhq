# frozen_string_literal: true

# == EnforcesAdminAuthentication
#
# Controller concern to enforce that users are authenticated as admins
#
# Upon inclusion, adds `authenticate_admin!` as a before_action
#
module EnforcesAdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  def authenticate_admin!
    return render_404 unless current_user.admin?
    return unless Feature.enabled?(:user_mode_in_session)

    unless current_user_mode.admin_mode?
      current_user_mode.request_admin_mode!
      store_location_for(:redirect, request.fullpath) if storable_location?
      redirect_to(new_admin_session_path, notice: _('Re-authentication required'))
    end
  end

  def storable_location?
    request.path != new_admin_session_path
  end
end

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

    def self.authorize!(ability, only:)
      actions = Array(only)

      skip_before_action :authenticate_admin!, only: actions
      prepend_before_action -> { authorize_ability!(ability) }, only: actions
    end
  end

  def authenticate_admin!
    attempt_admin_mode unless current_user&.can_admin_all_resources?
  end

  def storable_location?
    request.path != new_admin_session_path
  end

  private

  def authorize_ability!(ability)
    attempt_admin_mode unless current_user&.can?(ability)
  end

  def attempt_admin_mode
    return render_404 if in_admin_mode? || !current_user&.can_access_admin_area?

    current_user_mode.request_admin_mode!
    store_location_for(:redirect, request.fullpath) if storable_location?
    redirect_to(new_admin_session_path, notice: _('Re-authentication required'))
  end

  def in_admin_mode?
    Gitlab::CurrentSettings.admin_mode && current_user_mode.admin_mode?
  end
end

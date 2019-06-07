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
    render_404 unless current_user.admin?
  end
end

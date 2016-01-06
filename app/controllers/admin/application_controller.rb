# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'

  def authenticate_admin!
    return render_404 unless current_user.is_admin?
  end

  def authorize_impersonator!
    if session[:impersonator_id]
      User.find_by!(username: session[:impersonator_id]).admin?
    end
  end
end

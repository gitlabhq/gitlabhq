# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_title

  def authenticate_admin!
    return render_404 unless current_user.is_admin?
  end

  def set_title
    @title      = "Admin area"
    @title_url  = admin_root_path
    @sidebar    = "admin"
  end
end

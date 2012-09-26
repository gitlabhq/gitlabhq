# Provides a base class for Admin controllers to subclass
#
# Automatically ensures an administrator is logged in
class AdminController < ApplicationController
  before_filter :authenticate_admin!

  def authenticate_admin!
    return render_404 unless current_user.is_admin?
  end
end

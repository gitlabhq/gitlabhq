class Groups::ApplicationController < ApplicationController

  private
  
  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end
end

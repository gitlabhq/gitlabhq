class Groups::ApplicationController < ApplicationController

  private
  
  def authorize_read_group!
    unless @group and can?(current_user, :read_group, @group)
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
    end
  end
  
  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end

  def determine_layout
    if current_user
      'group'
    else
      'public_group'
    end
  end
end

class Groups::ApplicationController < ApplicationController
  before_action :set_title

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
    unless can?(current_user, :admin_group, group)
      return render_404
    end
  end

  def set_title
    @title      = group.name
    @title_url  = group_path(group)
    @sidebar    = "group"
  end
end

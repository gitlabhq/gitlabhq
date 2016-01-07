class Groups::ApplicationController < ApplicationController
  layout 'group'
  before_action :group

  private

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

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

  def authorize_admin_group_member!
    unless can?(current_user, :admin_group_member, group)
      return render_403
    end
  end
end

class Groups::ApplicationController < ApplicationController
  layout 'group'
  before_action :find_group

  private

  def find_group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def find_projects
    @projects ||= ProjectsFinder.new.execute(current_user, group: @group)
  end

  def authorize_read_group!
    unless can?(current_user, :read_group, @group)
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
    end
  end

  def authorize_admin_group!
    unless can?(current_user, :admin_group, @group)
      return render_404
    end
  end

  def authorize_admin_group_member!
    unless can?(current_user, :admin_group_member, @group)
      return render_403
    end
  end
end

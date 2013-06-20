class Groups::ApplicationController < ApplicationController
  respond_to :html
  layout 'group'

  # Authorize
  before_filter :authorize_read_group!

  protected

  def group
    @group ||= Group.find_by_path(params[:group_id])
  end

  def projects
    @projects ||= current_user.authorized_projects.where(namespace_id: group.id).sorted_by_activity
  end

  def project_ids
    projects.map(&:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless projects.present? or can?(current_user, :manage_group, @group)
      return render_404
    end
  end

  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end

end

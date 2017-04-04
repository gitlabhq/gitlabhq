class Dashboard::GroupsController < Dashboard::ApplicationController
  def index
    @group_members = current_user.group_members.includes(source: :route).joins(:group)
    @group_members = @group_members.merge(Group.search(params[:filter_groups])) if params[:filter_groups].present?
    @group_members = @group_members.merge(Group.sort(@sort = params[:sort]))
    @group_members = @group_members.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/groups/_groups", locals: { group_members: @group_members })
        }
      end
    end
  end
end

class Explore::GroupsController < Explore::ApplicationController
  def index
    @groups = GroupsFinder.new(current_user).execute
    @groups = @groups.search(params[:filter_groups]) if params[:filter_groups].present?
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("explore/groups/_groups", locals: { groups: @groups })
        }
      end
    end
  end
end

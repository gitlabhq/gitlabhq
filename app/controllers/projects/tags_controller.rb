class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  def index
    @tags = Kaminari.paginate_array(@project.repository.tags).page(params[:page]).per(30)
  end

  def create
    @project.repository.add_tag(params[:tag_name], params[:ref])

    redirect_to project_tags_path(@project)
  end

  def destroy
    tag = @project.repository.tags.find { |tag| tag.name == params[:id] }

    if tag && @project.repository.rm_tag(tag.name)
      Event.create_rm_ref(@project, current_user, tag, 'refs/tags')
    end

    respond_to do |format|
      format.html { redirect_to project_tags_path }
      format.js { render nothing: true }
    end
  end
end

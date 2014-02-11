class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  def index
    @tags = Kaminari.paginate_array(@repository.tags.reverse).page(params[:page]).per(30)
  end

  def create
    @repository.add_tag(params[:tag_name], params[:ref])

    if new_tag = @repository.find_tag(params[:tag_name])
      Event.create_ref_event(@project, current_user, new_tag, 'add', 'refs/tags')
    end

    redirect_to project_tags_path(@project)
  end

  def destroy
    tag = @repository.find_tag(params[:id])

    if tag && @repository.rm_tag(tag.name)
      Event.create_ref_event(@project, current_user, tag, 'rm', 'refs/tags')
    end

    respond_to do |format|
      format.html { redirect_to project_tags_path }
      format.js { render nothing: true }
    end
  end
end

class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  def index
    sorted = VersionSorter.rsort(@repository.tag_names)
    @tags = Kaminari.paginate_array(sorted).page(params[:page]).per(30)
  end

  def create
    @tag = CreateTagService.new.execute(@project, params[:tag_name],
                                        params[:ref], current_user)

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

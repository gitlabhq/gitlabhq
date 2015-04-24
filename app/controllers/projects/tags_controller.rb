class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:create]
  before_action :authorize_admin_project!, only: [:destroy]

  def index
    sorted = VersionSorter.rsort(@repository.tag_names)
    @tags = Kaminari.paginate_array(sorted).page(params[:page]).per(PER_PAGE)
  end

  def create
    result = CreateTagService.new(@project, current_user).
      execute(params[:tag_name], params[:ref], params[:message])

    if result[:status] == :success
      @tag = result[:tag]
      redirect_to namespace_project_tags_path(@project.namespace, @project)
    else
      @error = result[:message]
      render action: 'new'
    end
  end

  def destroy
    DeleteTagService.new(project, current_user).execute(params[:id])

    respond_to do |format|
      format.html do
        redirect_to namespace_project_tags_path(@project.namespace,
                                                @project)
      end
      format.js
    end
  end
end

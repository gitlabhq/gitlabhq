class Projects::TagsController < Projects::ApplicationController
  # Authorize
  before_filter :require_non_empty_project
  before_filter :authorize_download_code!
  before_filter :authorize_push_code!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  def index
    sorted = VersionSorter.rsort(@repository.tag_names)
    @tags = Kaminari.paginate_array(sorted).page(params[:page]).per(30)
  end

  def create
    result = CreateTagService.new(@project, current_user).
      execute(params[:tag_name], params[:ref], params[:message])
    if result[:status] == :success
      @tag = result[:tag]
      redirect_to project_tags_path(@project)
    else
      @error = result[:message]
      render action: 'new'
    end
  end

  def destroy
    tag = @repository.find_tag(params[:id])

    if tag && @repository.rm_tag(tag.name)
      Event.create_ref_event(@project, current_user, tag, 'rm', 'refs/tags')
    end

    respond_to do |format|
      format.html { redirect_to project_tags_path }
      format.js
    end
  end
end

class ServicesController < ProjectResourceController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  def index
    @gitlab_ci_service = @project.gitlab_ci_service
  end

  def edit
    @service = @project.gitlab_ci_service

    # Create if missing
    @service = @project.create_gitlab_ci_service unless @service
  end

  def update
    @service = @project.gitlab_ci_service

    if @service.update_attributes(params[:service])
      redirect_to edit_project_service_path(@project, :gitlab_ci)
    else
      render 'edit'
    end
  end

  def test
    commits = project.repository.commits(project.default_branch, nil, 3)
    data = project.post_receive_data(commits.last.id, commits.first.id, "refs/heads/#{project.default_branch}", current_user)

    @service = project.gitlab_ci_service
    @service.execute(data)

    redirect_to :back
  end
end

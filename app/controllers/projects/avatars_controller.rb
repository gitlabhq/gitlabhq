class Projects::AvatarsController < Projects::ApplicationController
  before_action :project

  def show
    repository = @project.repository
    @blob = repository.blob_at_branch('master', @project.avatar_in_git)
    if @blob
      headers['X-Content-Type-Options'] = 'nosniff'
      headers['Gitlab-Workhorse-Repo-Path'] = repository.path_to_repo
      headers['Gitlab-Workhorse-Send-Blob'] = @blob.id
      headers['Content-Disposition'] = 'inline'
      render nothing: true, content_type: @blob.content_type
    else
      render_404
    end
  end

  def destroy
    @project.remove_avatar!

    @project.save
    @project.reset_events_cache

    redirect_to edit_project_path(@project)
  end
end

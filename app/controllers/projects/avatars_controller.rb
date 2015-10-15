class Projects::AvatarsController < Projects::ApplicationController
  before_action :project

  def show
    @blob = @project.repository.blob_at_branch('master', @project.avatar_in_git)
    if @blob
      headers['X-Content-Type-Options'] = 'nosniff'
      send_data(
        @blob.data,
        type: @blob.mime_type,
        disposition: 'inline',
        filename: @blob.name
      )
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

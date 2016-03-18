class Projects::AvatarsController < Projects::ApplicationController
  include BlobHelper

  before_action :project

  def show
    @blob = @repository.blob_at_branch('master', @project.avatar_in_git)
    if @blob
      headers['X-Content-Type-Options'] = 'nosniff'

      return if cached_blob?

      headers.store(*Gitlab::Workhorse.send_git_blob(@repository, @blob))
      headers['Content-Disposition'] = 'inline'
      headers['Content-Type'] = safe_content_type(@blob)
      head :ok # 'render nothing: true' messes up the Content-Type
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

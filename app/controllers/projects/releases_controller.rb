class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_push_code!
  before_action :tag
  before_action :release

  def edit
  end

  def update
    # Release belongs to Tag which is not active record object,
    # it exists only to save a description to each Tag.
    # If description is empty we should destroy the existing record.
    if release_params[:description].present?
      release.update_attributes(release_params)
    else
      release.destroy
    end

    redirect_to project_tag_path(@project, @tag.name)
  end

  private

  def tag
    @tag ||= @repository.find_tag(params[:tag_id])
  end

  def release
    @release ||= @project.releases.find_or_initialize_by(tag: @tag.name)
  end

  def release_params
    params.require(:release).permit(:description)
  end
end

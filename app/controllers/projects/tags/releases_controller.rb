# frozen_string_literal: true

class Projects::Tags::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_push_code!
  before_action :tag
  before_action :release

  def edit
  end

  def update
    if release_params[:description].present?
      release.update(release_params)
    else
      release.destroy
    end

    redirect_to project_tag_path(@project, tag.name)
  end

  private

  def tag
    @tag ||= @repository.find_tag(params[:tag_id])
  end

  def release
    @release ||= Releases::CreateService.new(project, current_user, tag: @tag.name)
                                        .find_or_build_release
  end

  def release_params
    params.require(:release).permit(:description)
  end
end

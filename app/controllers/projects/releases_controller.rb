# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_push_code!, except: [:index]
  before_action :tag, except: [:index]
  before_action :release, except: [:index]
  before_action :check_releases_page_feature_flag, only: [:index]

  def index
  end

  def edit
  end

  def update
    # Release belongs to Tag which is not active record object,
    # it exists only to save a description to each Tag.
    # If description is empty we should destroy the existing record.
    if release_params[:description].present?
      release.update(release_params)
    else
      release.destroy
    end

    redirect_to project_tag_path(@project, @tag.name)
  end

  private

  def check_releases_page_feature_flag
    return render_404 unless Feature.enabled?(:releases_page)

    push_frontend_feature_flag(:releases_page)
  end

  def tag
    @tag ||= @repository.find_tag(params[:tag_id])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def release
    @release ||= @project.releases.find_or_initialize_by(tag: @tag.name)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def release_params
    params.require(:release).permit(:description)
  end
end

# frozen_string_literal: true

class Projects::UploadsController < Projects::ApplicationController
  include UploadsActions
  include WorkhorseRequest

  # These will kick you out if you don't have access.
  skip_before_action :project, :repository,
    if: -> { bypass_auth_checks_on_uploads? }

  before_action :authorize_upload_file!, only: [:create, :authorize]
  before_action :verify_workhorse_api!, only: [:authorize]
  before_action :disallow_new_uploads!, only: :show

  feature_category :team_planning

  private

  # Starting with this version, #show is handled by Banzai::UploadsController#show
  def disallow_new_uploads!
    render_404 if upload_version_at_least?(ID_BASED_UPLOAD_PATH_VERSION)
  end

  def upload_model_class
    Project
  end

  def uploader_class
    FileUploader
  end

  def target_project
    model
  end

  def find_model
    return @project if @project

    namespace = params[:namespace_id]
    id = params[:project_id]

    Project.find_by_full_path("#{namespace}/#{id}")
  end
end

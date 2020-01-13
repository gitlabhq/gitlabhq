# frozen_string_literal: true

class Projects::UploadsController < Projects::ApplicationController
  include UploadsActions
  include WorkhorseRequest

  # These will kick you out if you don't have access.
  skip_before_action :project, :repository,
    if: -> { action_name == 'show' && embeddable? }

  before_action :authorize_upload_file!, only: [:create, :authorize]
  before_action :verify_workhorse_api!, only: [:authorize]

  private

  def upload_model_class
    Project
  end

  def uploader_class
    FileUploader
  end

  def find_model
    return @project if @project

    namespace = params[:namespace_id]
    id = params[:project_id]

    Project.find_by_full_path("#{namespace}/#{id}")
  end

  # Overrides ApplicationController#build_canonical_path since there are
  # multiple routes that match project uploads:
  # https://gitlab.com/gitlab-org/gitlab/issues/196396
  def build_canonical_path(project)
    return super unless action_name == 'show'
    return super unless params[:secret] && params[:filename]

    show_namespace_project_uploads_url(project.namespace.to_param, project.to_param, params[:secret], params[:filename])
  end
end

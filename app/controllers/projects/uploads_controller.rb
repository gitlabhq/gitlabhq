class Projects::UploadsController < Projects::ApplicationController
  include UploadsActions

  skip_before_action :project, :repository,
    if: -> { action_name == 'show' && image_or_video? }

  before_action :authorize_upload_file!, only: [:create]

  private

  def show_model
    strong_memoize(:show_model) do
      namespace = params[:namespace_id]
      id = params[:project_id]

      Project.find_by_full_path("#{namespace}/#{id}")
    end
  end

  alias_method :model, :project
end

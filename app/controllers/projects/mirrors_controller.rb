class Projects::MirrorsController < Projects::ApplicationController
  include RepositorySettingsRedirect

  # Authorize
  before_action :authorize_admin_mirror!
  before_action :remote_mirror, only: [:update]

  layout "project_settings"

  def show
    redirect_to_repository_settings(project)
  end

  def update
    if project.update_attributes(mirror_params)
      flash[:notice] = 'Mirroring settings were successfully updated.'
    else
      flash[:alert] = project.errors.full_messages.join(', ').html_safe
    end

    respond_to do |format|
      format.html { redirect_to_repository_settings(project) }
      format.json do
        if project.errors.present?
          render json: project.errors, status: :unprocessable_entity
        else
          render json: ProjectMirrorSerializer.new.represent(project)
        end
      end
    end
  end

  def update_now
    if params[:sync_remote]
      project.update_remote_mirrors
      flash[:notice] = "The remote repository is being updated..."
    end

    redirect_to_repository_settings(project)
  end

  private

  def remote_mirror
    @remote_mirror = project.remote_mirrors.first_or_initialize
  end

  def mirror_params_attributes
    [
      remote_mirrors_attributes: %i[
        url
        id
        enabled
        only_protected_branches
      ]
    ]
  end

  def mirror_params
    params.require(:project).permit(mirror_params_attributes)
  end
end

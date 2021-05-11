# frozen_string_literal: true

class Projects::MirrorsController < Projects::ApplicationController
  include RepositorySettingsRedirect

  # Authorize
  before_action :remote_mirror, only: [:update]
  before_action :check_mirror_available!
  before_action :authorize_admin_project!

  layout "project_settings"

  feature_category :source_code_management

  def show
    redirect_to_repository_settings(project, anchor: 'js-push-remote-settings')
  end

  def update
    result = ::Projects::UpdateService.new(project, current_user, mirror_params).execute

    if result[:status] == :success
      flash[:notice] = _('Mirroring settings were successfully updated.')
    else
      flash[:alert] = project.errors.full_messages.join(', ').html_safe
    end

    respond_to do |format|
      format.html { redirect_to_repository_settings(project, anchor: 'js-push-remote-settings') }
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
      flash[:notice] = _("The remote repository is being updated...")
    end

    redirect_to_repository_settings(project, anchor: 'js-push-remote-settings')
  end

  def ssh_host_keys
    lookup = SshHostKey.new(project: project, url: params[:ssh_url], compare_host_keys: params[:compare_host_keys])

    if lookup.error.present?
      # Failed to read keys
      render json: { message: lookup.error }, status: :bad_request
    elsif lookup.known_hosts.nil?
      # Still working, come back later
      render body: nil, status: :no_content
    else
      render json: lookup
    end
  rescue ArgumentError => err
    render json: { message: err.message }, status: :bad_request
  end

  private

  def remote_mirror
    @remote_mirror = project.remote_mirrors.first_or_initialize
  end

  def check_mirror_available!
    render_404 unless can?(current_user, :admin_remote_mirror, project)
  end

  def mirror_params_attributes
    [
      remote_mirrors_attributes: %i[
        url
        id
        enabled
        only_protected_branches
        keep_divergent_refs
        auth_method
        password
        ssh_known_hosts
        regenerate_ssh_private_key
        _destroy
      ]
    ]
  end

  def mirror_params
    params.require(:project).permit(mirror_params_attributes)
  end
end

Projects::MirrorsController.prepend_mod_with('Projects::MirrorsController')

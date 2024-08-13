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
    if push_mirror_create_or_destroy?
      result = execute_push_mirror_service

      if result.success?
        flash[:notice] = notice_message
      else
        flash[:alert] = alert_error(result.message)
      end

      respond_to do |format|
        format.html { redirect_to_repository_settings(project, anchor: 'js-push-remote-settings') }
        format.json do
          if result.error?
            render json: result.message, status: :unprocessable_entity
          else
            render json: ProjectMirrorSerializer.new.represent(project)
          end
        end
      end
    else
      flash[:alert] = alert_error('Invalid mirror update request')

      respond_to do |format|
        format.html { redirect_to_repository_settings(project, anchor: 'js-push-remote-settings') }
        format.json do
          render json: { error: flash[:alert] }, status: :bad_request
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
  rescue ArgumentError => e
    render json: { message: e.message }, status: :bad_request
  end

  private

  def push_mirror_create_or_destroy?
    push_mirror_create? || push_mirror_destroy?
  end

  def push_mirror_create?
    push_mirror_attributes.present?
  end

  def push_mirror_destroy?
    ::Gitlab::Utils.to_boolean(mirror_params.dig(:remote_mirrors_attributes, '_destroy'))
  end

  def push_mirror_attributes
    mirror_params.dig(:remote_mirrors_attributes, '0')
  end

  def execute_push_mirror_service
    if push_mirror_create?
      return ::RemoteMirrors::CreateService.new(project, current_user, push_mirror_attributes).execute
    end

    return unless push_mirror_destroy?

    ::RemoteMirrors::DestroyService.new(project, current_user).execute(push_mirror_to_destroy)
  end

  def safe_mirror_params
    mirror_params
  end

  def notice_message
    _('Mirroring settings were successfully updated.')
  end

  def push_mirror_to_destroy
    push_mirror_to_destroy_id = safe_mirror_params.dig(:remote_mirrors_attributes, 'id')

    project.remote_mirrors.find(push_mirror_to_destroy_id)
  end

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
        user
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

  def alert_error(error)
    return error.full_messages.to_sentence if error.respond_to?(:full_messages)

    error
  end
end

Projects::MirrorsController.prepend_mod_with('Projects::MirrorsController')

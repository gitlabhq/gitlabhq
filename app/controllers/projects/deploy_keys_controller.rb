class Projects::DeployKeysController < Projects::ApplicationController
  include RepositorySettingsRedirect
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    redirect_to_repository_settings(@project)
  end

  def new
    redirect_to_repository_settings(@project)
  end

  def create
    @key = DeployKey.new(deploy_key_params.merge(user: current_user))

    unless @key.valid? && @project.deploy_keys << @key
<<<<<<< HEAD
      flash[:alert] = @key.errors.full_messages.join(', ').html_safe
    else
      log_audit_event(@key.title, action: :create)
=======
      flash[:alert] = @key.errors.full_messages.join(', ').html_safe      
>>>>>>> ce/master
    end
    redirect_to_repository_settings(@project)
  end

  def enable
    load_key
    Projects::EnableDeployKeyService.new(@project, current_user, params).execute
    log_audit_event(@key.title, action: :create)

    redirect_to_repository_settings(@project)
  end

  def disable
    load_key
    @project.deploy_keys_projects.find_by(deploy_key_id: params[:id]).destroy
    log_audit_event(@key.title, action: :destroy)

    redirect_to_repository_settings(@project)
  end

  protected

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title, :can_push)
<<<<<<< HEAD
  end

  def log_audit_event(key_title, options = {})
    AuditEventService.new(current_user, @project, options)
      .for_deploy_key(key_title).security_event
  end

  def load_key
    @key ||= current_user.accessible_deploy_keys.find(params[:id])
=======
>>>>>>> ce/master
  end
end

class Projects::GitHttpController < Projects::GitHttpClientController
  include WorkhorseRequest

  before_action :access_check

  rescue_from Gitlab::GitAccess::UnauthorizedError, with: :render_403
  rescue_from Gitlab::GitAccess::NotFoundError, with: :render_404

  # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
  # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
  def info_refs
    log_user_activity if upload_pack?

    if user && project.blank? && receive_pack?
      @project = ::Projects::CreateService.new(user, project_params).execute

      if @project.saved?
        Gitlab::Checks::NewProject.new(user, @project, 'http').add_new_project_message
      else
        raise Gitlab::GitAccess::NotFoundError, 'Could not create project'
      end
    end

    render_ok
  end

  # POST /foo/bar.git/git-upload-pack (git pull)
  def git_upload_pack
    render_ok
  end

  # POST /foo/bar.git/git-receive-pack" (git push)
  def git_receive_pack
    raise Gitlab::GitAccess::NotFoundError, 'Could not create project' unless project

    render_ok
  end

  private

  def download_request?
    upload_pack?
  end

  def upload_pack?
    git_command == 'git-upload-pack'
  end

  def receive_pack?
    git_command == 'git-receive-pack'
  end

  def git_command
    if action_name == 'info_refs'
      params[:service]
    else
      action_name.dasherize
    end
  end

  def render_ok
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.git_http_ok(repository, wiki?, user, action_name)
  end

  def render_403(exception)
    render plain: exception.message, status: :forbidden
  end

  def render_404(exception)
    render plain: exception.message, status: :not_found
  end

  def access
    @access ||= access_klass.new(access_actor, project, 'http', authentication_abilities: authentication_abilities, redirected_path: redirected_path, target_namespace: namespace)
  end

  def access_actor
    return user if user
    return :ci if ci?
  end

  def access_check
    # Use the magic string '_any' to indicate we do not know what the
    # changes are. This is also what gitlab-shell does.
    access.check(git_command, '_any')
  end

  def access_klass
    @access_klass ||= wiki? ? Gitlab::GitAccessWiki : Gitlab::GitAccess
  end

  def project_params
    {
        description: "",
        path: Project.parse_project_id(params[:project_id]),
        namespace_id: namespace&.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s
    }
  end

  def namespace
    @namespace ||= Namespace.find_by_path_or_name(params[:namespace_id])
  end

  def log_user_activity
    Users::ActivityService.new(user, 'pull').execute
  end
end

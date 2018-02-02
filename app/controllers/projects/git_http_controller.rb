class Projects::GitHttpController < Projects::GitHttpClientController
  include WorkhorseRequest

  before_action :access_check

  rescue_from Gitlab::GitAccess::UnauthorizedError, with: :render_403
  rescue_from Gitlab::GitAccess::NotFoundError, with: :render_404
  rescue_from Gitlab::GitAccess::ProjectCreationError, with: :render_422

  # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
  # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
  def info_refs
    log_user_activity if upload_pack?

    render_ok
  end

  # POST /foo/bar.git/git-upload-pack (git pull)
  def git_upload_pack
    render_ok
  end

  # POST /foo/bar.git/git-receive-pack" (git push)
  def git_receive_pack
    render_ok
  end

  private

  def download_request?
    upload_pack?
  end

  def upload_pack?
    git_command == 'git-upload-pack'
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

  def render_422(exception)
    render plain: exception.message, status: :unprocessable_entity
  end

  def access
    @access ||= access_klass.new(access_actor, project,
      'http', authentication_abilities: authentication_abilities,
              namespace_path: params[:namespace_id], project_path: project_path,
              redirected_path: redirected_path)
  end

  def access_actor
    return user if user
    return :ci if ci?
  end

  def access_check
    # Use the magic string '_any' to indicate we do not know what the
    # changes are. This is also what gitlab-shell does.
    access.check(git_command, '_any')
    @project ||= access.project
  end

  def access_klass
    @access_klass ||= wiki? ? Gitlab::GitAccessWiki : Gitlab::GitAccess
  end

  def project_path
    @project_path ||= params[:project_id].sub(/\.git$/, '')
  end

  def log_user_activity
    Users::ActivityService.new(user, 'pull').execute
  end
end

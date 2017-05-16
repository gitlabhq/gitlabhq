class Projects::GitHttpController < Projects::GitHttpClientController
  include WorkhorseRequest

  # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
  # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
  def info_refs
    if upload_pack? && upload_pack_allowed?
      log_user_activity

      render_ok
    elsif receive_pack? && receive_pack_allowed?
      render_ok
    elsif http_blocked?
      render_http_not_allowed
    else
      render_denied
    end
  end

  # POST /foo/bar.git/git-upload-pack (git pull)
  def git_upload_pack
    if upload_pack? && upload_pack_allowed?
      render_ok
    else
      render_denied
    end
  end

  # POST /foo/bar.git/git-receive-pack" (git push)
  def git_receive_pack
    if receive_pack? && receive_pack_allowed?
      render_ok
    else
      render_denied
    end
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

  def render_http_not_allowed
    render plain: access_check.message, status: :forbidden
  end

  def render_denied
    if access_check.message == Gitlab::GitAccess::ERROR_MESSAGES[:project_not_found]
      render plain: access_check.message, status: :not_found
    else
      render plain: access_check.message, status: :forbidden
    end
  end

  def upload_pack_allowed?
    access_check.allowed?
  end

  def access
    @access ||= access_klass.new(access_actor, project, 'http', authentication_abilities: authentication_abilities)
  end

  def access_actor
    return user if user
    return :ci if ci?
  end

  def access_check
    # Use the magic string '_any' to indicate we do not know what the
    # changes are. This is also what gitlab-shell does.
    @access_check ||= access.check(git_command, '_any')
  end

  def http_blocked?
    !access.protocol_allowed?
  end

  def receive_pack_allowed?
    access_check.allowed?
  end

  def access_klass
    @access_klass ||= wiki? ? Gitlab::GitAccessWiki : Gitlab::GitAccess
  end

  def log_user_activity
    Users::ActivityService.new(user, 'pull').execute
  end
end

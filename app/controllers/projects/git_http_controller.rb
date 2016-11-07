# This file should be identical in GitLab Community Edition and Enterprise Edition

class Projects::GitHttpController < Projects::GitHttpClientController
  before_action :verify_workhorse_api!

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
    render json: Gitlab::Workhorse.git_http_ok(repository, user)
  end

  def render_http_not_allowed
    render plain: access_check.message, status: :forbidden
  end

  def render_denied
    if user && user.can?(:read_project, project)
      message = project.above_size_limit? ? access_check.message : 'Access denied'

      render plain: message, status: :forbidden
    else
      # Do not leak information about project existence
      render_not_found
    end
  end

  def upload_pack_allowed?
    return false unless Gitlab.config.gitlab_shell.upload_pack

    access_check.allowed? || ci?
  end

  def access
    @access ||= Gitlab::GitAccess.new(user, project, 'http', authentication_abilities: authentication_abilities)
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
    return false unless Gitlab.config.gitlab_shell.receive_pack

    access_check.allowed?
  end

  def log_user_activity
    Users::ActivityService.new(user, 'pull').execute
  end
end

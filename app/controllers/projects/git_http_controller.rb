# This file should be identical in GitLab Community Edition and Enterprise Edition

class Projects::GitHttpController < Projects::ApplicationController
  include ActionController::HttpAuthentication::Basic
  include KerberosSpnegoHelper

  attr_reader :user

  # Git clients will not know what authenticity token to send along
  skip_before_action :verify_authenticity_token
  skip_before_action :repository
  before_action :authenticate_user
  before_action :ensure_project_found!

  # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
  # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
  def info_refs
    if upload_pack? && upload_pack_allowed?
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

  def authenticate_user
    if project && project.public? && upload_pack?
      return # Allow access
    end

    if allow_basic_auth? && basic_auth_provided?
      login, password = user_name_and_password(request)
      auth_result = Gitlab::Auth.find_for_git_client(login, password, project: project, ip: request.ip)

      if auth_result.type == :ci && upload_pack?
        @ci = true
      elsif auth_result.type == :oauth && !upload_pack?
        # Not allowed
      else
        @user = auth_result.user
      end

      if ci? || user
        return # Allow access
      end
    elsif allow_kerberos_spnego_auth? && spnego_provided?
      @user = find_kerberos_user

      if user
        send_final_spnego_response
        return # Allow access
      end
    end

    send_challenges
    render plain: "HTTP Basic: Access denied\n", status: 401
  end

  def basic_auth_provided?
    has_basic_credentials?(request)
  end

  def send_challenges
    challenges = []
    challenges << 'Basic realm="GitLab"' if allow_basic_auth?
    challenges << spnego_challenge if allow_kerberos_spnego_auth?
    headers['Www-Authenticate'] = challenges.join("\n") if challenges.any?
  end

  def ensure_project_found!
    render_not_found if project.blank?
  end

  def project
    return @project if defined?(@project)

    project_id, _ = project_id_with_suffix
    if project_id.blank?
      @project = nil
    else
      @project = Project.find_with_namespace("#{params[:namespace_id]}/#{project_id}")
    end
  end

  # This method returns two values so that we can parse
  # params[:project_id] (untrusted input!) in exactly one place.
  def project_id_with_suffix
    id = params[:project_id] || ''

    %w[.wiki.git .git].each do |suffix|
      if id.end_with?(suffix)
        # Be careful to only remove the suffix from the end of 'id'.
        # Accidentally removing it from the middle is how security
        # vulnerabilities happen!
        return [id.slice(0, id.length - suffix.length), suffix]
      end
    end

    # Something is wrong with params[:project_id]; do not pass it on.
    [nil, nil]
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
    render json: Gitlab::Workhorse.git_http_ok(repository, user)
  end

  def repository
    _, suffix = project_id_with_suffix
    if suffix == '.wiki.git'
      project.wiki.repository
    else
      project.repository
    end
  end

  def render_not_found
    render plain: 'Not Found', status: :not_found
  end

  def render_http_not_allowed
    render plain: access_check.message, status: :forbidden
  end

  def render_denied
    if user && user.can?(:read_project, project)
      render plain: 'Access denied', status: :forbidden
    else
      # Do not leak information about project existence
      render_not_found
    end
  end

  def ci?
    @ci.present?
  end

  def upload_pack_allowed?
    return false unless Gitlab.config.gitlab_shell.upload_pack

    if user
      access_check.allowed?
    else
      ci? || project.public?
    end
  end

  def access
    @access ||= Gitlab::GitAccess.new(user, project, 'http')
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
end

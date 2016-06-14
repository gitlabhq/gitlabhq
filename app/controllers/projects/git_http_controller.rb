class Projects::GitHttpController < Projects::ApplicationController
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
    else
      render_not_found
    end
  end

  # POST /foo/bar.git/git-upload-pack (git pull)
  def git_upload_pack
    if upload_pack? && upload_pack_allowed?
      render_ok
    else
      render_not_found
    end
  end

  # POST /foo/bar.git/git-receive-pack" (git push)
  def git_receive_pack
    if receive_pack? && receive_pack_allowed?
      render_ok
    else
      render_not_found
    end
  end

  private

  def authenticate_user
    return if project && project.public? && upload_pack?

    authenticate_or_request_with_http_basic do |login, password|
      auth_result = Gitlab::Auth.find_for_git_client(login, password, project: project, ip: request.ip)

      if auth_result.type == :ci && upload_pack?
        @ci = true
      elsif auth_result.type == :oauth && !upload_pack?
        # Not allowed
      else
        @user = auth_result.user
      end

      ci? || user
    end
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
    render text: 'Not Found', status: :not_found
  end

  def ci?
    @ci.present?
  end

  def upload_pack_allowed?
    return false unless Gitlab.config.gitlab_shell.upload_pack

    if user
      Gitlab::GitAccess.new(user, project).download_access_check.allowed?
    else
      ci? || project.public?
    end
  end

  def receive_pack_allowed?
    return false unless Gitlab.config.gitlab_shell.receive_pack

    # Skip user authorization on upload request.
    # It will be done by the pre-receive hook in the repository.
    user.present?
  end
end

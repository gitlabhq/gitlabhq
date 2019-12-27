# frozen_string_literal: true

class Projects::GitHttpController < Projects::GitHttpClientController
  include WorkhorseRequest

  before_action :access_check
  prepend_before_action :deny_head_requests, only: [:info_refs]

  rescue_from Gitlab::GitAccess::UnauthorizedError, with: :render_403_with_exception
  rescue_from Gitlab::GitAccess::NotFoundError, with: :render_404_with_exception
  rescue_from Gitlab::GitAccess::ProjectCreationError, with: :render_422_with_exception
  rescue_from Gitlab::GitAccess::TimeoutError, with: :render_503_with_exception

  # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
  # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
  def info_refs
    log_user_activity if upload_pack?

    render_ok
  end

  # POST /foo/bar.git/git-upload-pack (git pull)
  def git_upload_pack
    enqueue_fetch_statistics_update

    render_ok
  end

  # POST /foo/bar.git/git-receive-pack" (git push)
  def git_receive_pack
    render_ok
  end

  private

  def deny_head_requests
    head :forbidden if request.head?
  end

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
    render json: Gitlab::Workhorse.git_http_ok(repository, repo_type, user, action_name)
  end

  def render_403_with_exception(exception)
    render plain: exception.message, status: :forbidden
  end

  def render_404_with_exception(exception)
    render plain: exception.message, status: :not_found
  end

  def render_422_with_exception(exception)
    render plain: exception.message, status: :unprocessable_entity
  end

  def render_503_with_exception(exception)
    render plain: exception.message, status: :service_unavailable
  end

  def enqueue_fetch_statistics_update
    return if repo_type.wiki?
    return unless project&.daily_statistics_enabled?

    ProjectDailyStatisticsWorker.perform_async(project.id)
  end

  def access
    @access ||= access_klass.new(access_actor, project, 'http',
      authentication_abilities: authentication_abilities,
      namespace_path: params[:namespace_id],
      project_path: project_path,
      redirected_path: redirected_path,
      auth_result_type: auth_result_type)
  end

  def access_actor
    return user if user
    return :ci if ci?
  end

  def access_check
    access.check(git_command, Gitlab::GitAccess::ANY)
    @project ||= access.project
  end

  def access_klass
    @access_klass ||= repo_type.access_checker_class
  end

  def project_path
    @project_path ||= params[:project_id].sub(/\.git$/, '')
  end

  def log_user_activity
    Users::ActivityService.new(user, 'pull').execute
  end
end

Projects::GitHttpController.prepend_if_ee('EE::Projects::GitHttpController')

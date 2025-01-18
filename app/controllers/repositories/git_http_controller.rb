# frozen_string_literal: true

module Repositories
  class GitHttpController < ::Repositories::GitHttpClientController
    include WorkhorseRequest

    before_action :access_check
    prepend_before_action :deny_head_requests, only: [:info_refs]

    rescue_from Gitlab::GitAccess::ForbiddenError, with: :render_403_with_exception
    rescue_from JWT::DecodeError, with: :render_403_with_exception
    rescue_from Gitlab::GitAccess::NotFoundError, with: :render_404_with_exception
    rescue_from Gitlab::GitAccessProject::CreationError, with: :render_422_with_exception
    rescue_from Gitlab::GitAccess::TimeoutError, with: :render_503_with_exception
    rescue_from GRPC::Unavailable do |e|
      render_503_with_exception(
        e,
        message: 'The git server, Gitaly, is not available at this time. Please contact your administrator.'
      )
    end

    # GET /foo/bar.git/info/refs?service=git-upload-pack (git pull)
    # GET /foo/bar.git/info/refs?service=git-receive-pack (git push)
    def info_refs
      log_user_activity if upload_pack?

      render_ok
    end

    # POST /foo/bar.git/git-upload-pack (git pull)
    def git_upload_pack
      update_fetch_statistics

      render_ok
    end

    # POST /foo/bar.git/git-receive-pack" (git push)
    def git_receive_pack
      render_ok
    end

    # POST /foo/bar.git/ssh-upload-pack" (git pull via SSH)
    def ssh_upload_pack
      render plain: "Not found", status: :not_found
    end

    # POST /foo/bar.git/ssh-receive-pack" (git push via SSH)
    def ssh_receive_pack
      render plain: "Not found", status: :not_found
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
      case action_name
      when 'info_refs'
        params[:service]
      when 'ssh_upload_pack'
        'git-upload-pack'
      when 'ssh_receive_pack'
        'git-receive-pack'
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

    def render_503_with_exception(exception, message: nil)
      render plain: message || exception.message, status: :service_unavailable
    end

    def update_fetch_statistics
      return unless project
      return if Gitlab::Database.read_only?
      return unless repo_type.project?
      return if Feature.enabled?(:disable_git_http_fetch_writes)

      Projects::FetchStatisticsIncrementService.new(project).execute
    end

    def access
      @access ||= access_klass.new(access_actor, container, 'http',
        authentication_abilities: authentication_abilities,
        repository_path: repository_path,
        redirected_path: redirected_path,
        auth_result_type: auth_result_type)
    end

    def access_actor
      return user if user

      :ci if ci?
    end

    def access_check
      access.check(git_command, Gitlab::GitAccess::ANY)

      @project = @container = access.container if repo_type.project? && !container
    end

    def access_klass
      @access_klass ||= repo_type.access_checker_class
    end

    def log_user_activity
      Users::ActivityService.new(author: user, project: project, namespace: project&.namespace).execute

      return unless project && user

      Gitlab::EventStore.publish(
        Users::ActivityEvent.new(data: {
          user_id: user.id,
          namespace_id: project.root_ancestor.id
        })
      )
    end

    def append_info_to_payload(payload)
      super

      payload[:metadata] ||= {}
      payload[:metadata][:repository_storage] = project&.repository_storage
    end
  end
end

::Repositories::GitHttpController.prepend_mod_with('Repositories::GitHttpController')

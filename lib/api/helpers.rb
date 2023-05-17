# frozen_string_literal: true

module API
  module Helpers
    include Gitlab::Utils
    include Helpers::Caching
    include Helpers::Pagination
    include Helpers::PaginationStrategies
    include Gitlab::Ci::Artifacts::Logger
    include Gitlab::Utils::StrongMemoize

    SUDO_HEADER = "HTTP_SUDO"
    GITLAB_SHARED_SECRET_HEADER = "Gitlab-Shared-Secret"
    GITLAB_SHELL_API_HEADER = "Gitlab-Shell-Api-Request"
    GITLAB_SHELL_JWT_ISSUER = "gitlab-shell"
    SUDO_PARAM = :sudo
    API_USER_ENV = 'gitlab.api.user'
    API_TOKEN_ENV = 'gitlab.api.token'
    API_EXCEPTION_ENV = 'gitlab.api.exception'
    API_RESPONSE_STATUS_CODE = 'gitlab.api.response_status_code'
    INTEGER_ID_REGEX = /^-?\d+$/.freeze

    def declared_params(options = {})
      options = { include_parent_namespaces: false }.merge(options)
      declared(params, options).to_h.symbolize_keys
    end

    def check_unmodified_since!(last_modified)
      if_unmodified_since = begin
        Time.parse(headers['If-Unmodified-Since'])
      rescue StandardError
        nil
      end

      if if_unmodified_since && last_modified && last_modified > if_unmodified_since
        render_api_error!('412 Precondition Failed', 412)
      end
    end

    def destroy_conditionally!(resource, last_updated: nil)
      last_updated ||= resource.updated_at

      check_unmodified_since!(last_updated)

      status 204
      body false

      if block_given?
        yield resource
      else
        resource.destroy
      end
    end

    def job_token_authentication?
      initial_current_user && @current_authenticated_job.present? # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    # Returns the job associated with the token provided for
    # authentication, if any
    def current_authenticated_job
      if try(:namespace_inheritable, :authentication)
        ci_build_from_namespace_inheritable
      else
        @current_authenticated_job # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    # We can't rewrite this with StrongMemoize because `sudo!` would
    # actually write to `@current_user`, and `sudo?` would immediately
    # call `current_user` again which reads from `@current_user`.
    # We should rewrite this in a way that using StrongMemoize is possible
    def current_user
      return @current_user if defined?(@current_user)

      @current_user = initial_current_user

      Gitlab::I18n.locale = @current_user&.preferred_language

      sudo!

      validate_access_token!(scopes: scopes_registered_for_endpoint) unless sudo?

      save_current_user_in_env(@current_user) if @current_user

      save_current_token_in_env

      if @current_user
        ::ApplicationRecord
          .sticking
          .stick_or_unstick_request(env, :user, @current_user.id)
      end

      @current_user
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def save_current_user_in_env(user)
      env[API_USER_ENV] = { user_id: user.id, username: user.username }
    end

    def save_current_token_in_env
      token = access_token
      env[API_TOKEN_ENV] = { token_id: token.id, token_type: token.class } if token

    rescue Gitlab::Auth::UnauthorizedError
    end

    def sudo?
      initial_current_user != current_user
    end

    def user_group
      @group ||= find_group!(params[:id])
    end

    def user_project
      @project ||= find_project!(params[:id])
    end

    def available_labels_for(label_parent, params = { include_ancestor_groups: true, only_group_labels: true })
      if label_parent.is_a?(Project)
        params.delete(:only_group_labels)
        params[:project_id] = label_parent.id
      else
        params[:group_id] = label_parent.id
      end

      LabelsFinder.new(current_user, params).execute
    end

    def find_user(id)
      UserFinder.new(id).find_by_id_or_username
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project(id)
      return unless id

      projects = Project.without_deleted.not_hidden

      if id.is_a?(Integer) || id =~ INTEGER_ID_REGEX
        projects.find_by(id: id)
      elsif id.include?("/")
        projects.find_by_full_path(id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_project!(id)
      project = find_project(id)

      return forbidden! unless authorized_project_scope?(project)

      return project if can?(current_user, :read_project, project)
      return unauthorized! if authenticate_non_public?

      not_found!('Project')
    end

    def authorized_project_scope?(project)
      return true unless job_token_authentication?
      return true unless route_authentication_setting[:job_token_scope] == :project

      ::Feature.enabled?(:ci_job_token_scope, project) &&
        current_authenticated_job.project == project
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_group(id)
      if id.to_s =~ INTEGER_ID_REGEX
        Group.find_by(id: id)
      else
        Group.find_by_full_path(id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_group!(id)
      group = find_group(id)
      check_group_access(group)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_group_by_full_path!(full_path)
      group = Group.find_by_full_path(full_path)
      check_group_access(group)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def check_group_access(group)
      return group if can?(current_user, :read_group, group)
      return unauthorized! if authenticate_non_public?

      not_found!('Group')
    end

    def check_namespace_access(namespace)
      return namespace if can?(current_user, :read_namespace, namespace)

      not_found!('Namespace')
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_namespace(id)
      if id.to_s =~ INTEGER_ID_REGEX
        Namespace.without_project_namespaces.find_by(id: id)
      else
        find_namespace_by_path(id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_namespace!(id)
      check_namespace_access(find_namespace(id))
    end

    def find_namespace_by_path(path)
      Namespace.without_project_namespaces.find_by_full_path(path)
    end

    def find_namespace_by_path!(path)
      check_namespace_access(find_namespace_by_path(path))
    end

    def find_branch!(branch_name)
      if Gitlab::GitRefValidator.validate(branch_name)
        user_project.repository.find_branch(branch_name) || not_found!('Branch')
      else
        render_api_error!('The branch refname is invalid', 400)
      end
    end

    def find_tag!(tag_name)
      if Gitlab::GitRefValidator.validate(tag_name)
        user_project.repository.find_tag(tag_name) || not_found!('Tag')
      else
        render_api_error!('The tag refname is invalid', 400)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_issue(iid, project_id = nil)
      project = project_id ? find_project!(project_id) : user_project

      ::IssuesFinder.new(
        current_user,
        project_id: project.id,
        issue_types: WorkItems::Type.allowed_types_for_issues
      ).find_by!(iid: iid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_merge_request(iid)
      MergeRequestsFinder.new(current_user, project_id: user_project.id).find_by!(iid: iid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_project_commit(id)
      user_project.commit_by(oid: id)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_merge_request_with_access(iid, access_level = :read_merge_request)
      merge_request = user_project.merge_requests.find_by!(iid: iid)
      authorize! access_level, merge_request
      merge_request
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_build!(id)
      user_project.builds.find(id.to_i)
    end

    def find_job!(id)
      user_project.processables.find(id.to_i)
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authenticate_non_get!
      authenticate! unless %w[GET HEAD].include?(route.request_method)
    end

    def authenticate_by_gitlab_shell_token!
      payload, _ = JSONWebToken::HMACToken.decode(headers[GITLAB_SHELL_API_HEADER], secret_token)
      unauthorized! unless payload['iss'] == GITLAB_SHELL_JWT_ISSUER
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature => ex
      Gitlab::ErrorTracking.track_exception(ex)
      unauthorized!
    end

    def authenticated_with_can_read_all_resources!
      authenticate!
      forbidden! unless current_user.can_read_all_resources?
    end

    def authenticated_as_admin!
      authenticate!
      forbidden! unless current_user.can_admin_all_resources?
    end

    def authorize!(action, subject = :global, reason = nil)
      forbidden!(reason) unless can?(current_user, action, subject)
    end

    def authorize_push_project
      authorize! :push_code, user_project
    end

    def authorize_admin_tag
      authorize! :admin_tag, user_project
    end

    def authorize_admin_project
      authorize! :admin_project, user_project
    end

    def authorize_admin_group
      authorize! :admin_group, user_group
    end

    def authorize_read_builds!
      authorize! :read_build, user_project
    end

    def authorize_read_code!
      authorize! :read_code, user_project
    end

    def authorize_read_build_trace!(build)
      authorize! :read_build_trace, build
    end

    def authorize_read_job_artifacts!(build)
      authorize! :read_job_artifacts, build
    end

    def authorize_destroy_artifacts!
      authorize! :destroy_artifacts, user_project
    end

    def authorize_update_builds!
      authorize! :update_build, user_project
    end

    def require_repository_enabled!(subject = :global)
      not_found!("Repository") unless user_project.feature_available?(:repository, current_user)
    end

    def require_gitlab_workhorse!
      verify_workhorse_api!

      unless env['HTTP_GITLAB_WORKHORSE'].present?
        forbidden!('Request should be executed via GitLab Workhorse')
      end
    end

    def verify_workhorse_api!
      Gitlab::Workhorse.verify_api_request!(request.headers)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)

      forbidden!
    end

    def require_pages_enabled!
      not_found! unless user_project.pages_available?
    end

    def require_pages_config_enabled!
      not_found! unless Gitlab.config.pages.enabled
    end

    def can?(object, action, subject = :global)
      Ability.allowed?(object, action, subject)
    end

    # Checks the occurrences of required attributes, each attribute must be present in the params hash
    # or a Bad Request error is invoked.
    #
    # Parameters:
    #   keys (required) - A hash consisting of keys that must be present
    def required_attributes!(keys)
      keys.each do |key|
        bad_request_missing_attribute!(key) unless params[key].present?
      end
    end

    def attributes_for_keys(keys, custom_params = nil)
      params_hash = custom_params || params
      attrs = {}
      keys.each do |key|
        if params_hash[key].present? || (params_hash.key?(key) && params_hash[key] == false)
          attrs[key] = params_hash[key]
        end
      end
      permitted_attrs = ActionController::Parameters.new(attrs).permit!
      permitted_attrs.to_h
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def filter_by_iid(items, iid)
      items.where(iid: iid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def filter_by_title(items, title)
      items.where(title: title)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def filter_by_search(items, text)
      items.search(text)
    end

    def order_options_with_tie_breaker
      order_by = if params[:order_by] == 'created_at'
                   'id'
                 else
                   params[:order_by]
                 end

      order_options = { order_by => params[:sort] }
      order_options['id'] ||= params[:sort] || 'asc'
      order_options
    end

    # error helpers

    def forbidden!(reason = nil)
      render_api_error_with_reason!(403, '403 Forbidden', reason)
    end

    def bad_request!(reason = nil)
      render_api_error_with_reason!(400, '400 Bad request', reason)
    end

    def bad_request_missing_attribute!(attribute)
      bad_request!("\"#{attribute}\" not given")
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      render_api_error!(message.join(' '), 404)
    end

    def check_sha_param!(params, merge_request)
      if params[:sha] && merge_request.diff_head_sha != params[:sha]
        render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
      end
    end

    def unauthorized!(reason = nil)
      render_api_error_with_reason!(401, '401 Unauthorized', reason)
    end

    def not_allowed!(message = nil)
      render_api_error!(message || '405 Method Not Allowed', :method_not_allowed)
    end

    def not_acceptable!
      render_api_error!('406 Not Acceptable', 406)
    end

    def service_unavailable!(message = nil)
      render_api_error!(message || '503 Service Unavailable', 503)
    end

    def conflict!(message = nil)
      render_api_error!(message || '409 Conflict', 409)
    end

    def unprocessable_entity!(message = nil)
      render_api_error!(message || '422 Unprocessable Entity', :unprocessable_entity)
    end

    def file_too_large!
      render_api_error!('413 Request Entity Too Large', 413)
    end

    def not_modified!
      render_api_error!('304 Not Modified', 304)
    end

    def no_content!
      render_api_error!('204 No Content', 204)
    end

    def created!
      render_api_error!('201 Created', 201)
    end

    def accepted!
      render_api_error!('202 Accepted', 202)
    end

    def render_validation_error!(model, status = 400)
      if model.errors.any?
        render_api_error!(model_errors(model).messages || '400 Bad Request', status)
      end
    end

    def model_errors(model)
      model.errors
    end

    def render_api_error_with_reason!(status, message, reason)
      message = [message]
      message << "- #{reason}" if reason
      render_api_error!(message.join(' '), status)
    end

    def render_api_error!(message, status)
      render_structured_api_error!({ 'message' => message }, status)
    end

    def render_structured_api_error!(hash, status)
      # Use this method instead of `render_api_error!` when you have additional top-level
      # hash entries in addition to 'message' which need to be passed to `#error!`
      set_status_code_in_env(status)
      error!(hash, status, header)
    end

    def set_status_code_in_env(status)
      # grape-logging doesn't pass the status code, so this is a
      # workaround for getting that information in the loggers:
      # https://github.com/aserafin/grape_logging/issues/71
      env[API_RESPONSE_STATUS_CODE] = Rack::Utils.status_code(status)
    end

    def handle_api_exception(exception)
      if report_exception?(exception)
        define_params_for_grape_middleware
        Gitlab::ApplicationContext.push(user: current_user, remote_ip: request.ip)
        Gitlab::ErrorTracking.track_exception(exception)
      end

      # This is used with GrapeLogging::Loggers::ExceptionLogger
      env[API_EXCEPTION_ENV] = exception

      # lifted from https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb#L60
      trace = exception.backtrace

      message = ["\n#{exception.class} (#{exception.message}):\n"]
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << trace.join("\n  ")
      message = message.join

      API.logger.add Logger::FATAL, message

      response_message =
        if Rails.env.test?
          message
        else
          '500 Internal Server Error'
        end

      rack_response({ 'message' => response_message }.to_json, 500)
    end

    # project helpers

    # rubocop: disable CodeReuse/ActiveRecord
    def reorder_projects(projects)
      projects.reorder(order_options_with_tie_breaker)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_finder_params
      project_finder_params_ce.merge(project_finder_params_ee)
    end

    # file helpers

    def present_disk_file!(path, filename, content_type = 'application/octet-stream')
      filename ||= File.basename(path)
      header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: filename)
      header['Content-Transfer-Encoding'] = 'binary'
      content_type content_type

      # Support download acceleration
      case headers['X-Sendfile-Type']
      when 'X-Sendfile'
        header['X-Sendfile'] = path
        body '' # to avoid an error from API::APIGuard::ResponseCoercerMiddleware
      else
        sendfile path
      end
    end

    def present_artifacts_file!(file, **args)
      log_artifacts_filesize(file&.model)

      present_carrierwave_file!(file, **args)
    end

    def present_carrierwave_file!(file, supports_direct_download: true)
      return not_found! unless file&.exists?

      if file.file_storage?
        present_disk_file!(file.path, file.filename)
      elsif supports_direct_download && file.class.direct_download_enabled?
        return redirect(ObjectStorage::S3.signed_head_url(file)) if request.head? && file.fog_credentials[:provider] == 'AWS'

        redirect(cdn_fronted_url(file))
      else
        header(*Gitlab::Workhorse.send_url(file.url))
        status :ok
        body '' # to avoid an error from API::APIGuard::ResponseCoercerMiddleware
      end
    end

    def cdn_fronted_url(file)
      if file.respond_to?(:cdn_enabled_url)
        result = file.cdn_enabled_url(ip_address)
        Gitlab::ApplicationContext.push(artifact_used_cdn: result.used_cdn)
        result.url
      else
        file.url
      end
    end

    def increment_counter(event_name)
      Gitlab::UsageDataCounters.count(event_name)
    rescue StandardError => error
      Gitlab::AppLogger.warn("Redis tracking event failed for event: #{event_name}, message: #{error.message}")
    end

    # @param event_name [String] the event name
    # @param values [Array|String] the values counted
    def increment_unique_values(event_name, values)
      return unless values.present?

      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: values)
    rescue StandardError => error
      Gitlab::AppLogger.warn("Redis tracking event failed for event: #{event_name}, message: #{error.message}")
    end

    def order_by_similarity?(allow_unauthorized: true)
      params[:order_by] == 'similarity' && params[:search].present? && (allow_unauthorized || current_user.present?)
    end

    protected

    def project_finder_params_visibility_ce
      finder_params = {}
      finder_params[:min_access_level] = params[:min_access_level] if params[:min_access_level]
      finder_params[:visibility_level] = Gitlab::VisibilityLevel.level_value(params[:visibility]) if params[:visibility]
      finder_params[:owned] = true if params[:owned].present?
      finder_params[:non_public] = true if params[:membership].present?
      finder_params[:starred] = true if params[:starred].present?
      finder_params[:archived] = archived_param unless params[:archived].nil?
      finder_params
    end

    def project_finder_params_ce
      finder_params = project_finder_params_visibility_ce

      finder_params.merge!(
        params
          .slice(:search,
                 :custom_attributes,
                 :last_activity_after,
                 :last_activity_before,
                 :topic,
                 :topic_id,
                 :repository_storage)
          .symbolize_keys
          .compact
      )

      finder_params[:with_issues_enabled] = true if params[:with_issues_enabled].present?
      finder_params[:with_merge_requests_enabled] = true if params[:with_merge_requests_enabled].present?
      finder_params[:search_namespaces] = true if params[:search_namespaces].present?
      finder_params[:user] = params.delete(:user) if params[:user]
      finder_params[:id_after] = sanitize_id_param(params[:id_after]) if params[:id_after]
      finder_params[:id_before] = sanitize_id_param(params[:id_before]) if params[:id_before]
      finder_params[:updated_after] = declared_params[:updated_after] if declared_params[:updated_after]
      finder_params[:updated_before] = declared_params[:updated_before] if declared_params[:updated_before]
      finder_params
    end

    # Overridden in EE
    def project_finder_params_ee
      {}
    end

    def validate_search_rate_limit!
      if current_user
        check_rate_limit!(:search_rate_limit, scope: [current_user])
      else
        check_rate_limit!(:search_rate_limit_unauthenticated, scope: [ip_address])
      end
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def initial_current_user
      return @initial_current_user if defined?(@initial_current_user)

      begin
        @initial_current_user = Gitlab::Auth::UniqueIpsLimiter.limit_user! { find_current_user! }
      rescue Gitlab::Auth::UnauthorizedError
        unauthorized!
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def sudo!
      return unless sudo_identifier

      unauthorized! unless initial_current_user

      unless initial_current_user.can_admin_all_resources?
        forbidden!('Must be admin to use sudo')
      end

      unless access_token
        forbidden!('Must be authenticated using an OAuth or Personal Access Token to use sudo')
      end

      validate_access_token!(scopes: [:sudo])

      sudoed_user = find_user(sudo_identifier)
      not_found!("User with ID or username '#{sudo_identifier}'") unless sudoed_user

      @current_user = sudoed_user # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def sudo_identifier
      @sudo_identifier ||= params[SUDO_PARAM] || env[SUDO_HEADER]
    end

    def secret_token
      Gitlab::Shell.secret_token
    end

    def authenticate_non_public?
      route_authentication_setting[:authenticate_non_public] && !current_user
    end

    def send_git_blob(repository, blob)
      env['api.format'] = :txt
      content_type 'text/plain'

      header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: blob.name)

      # Let Workhorse examine the content and determine the better content disposition
      header[Gitlab::Workhorse::DETECT_HEADER] = "true"

      header(*Gitlab::Workhorse.send_git_blob(repository, blob))

      body ''
    end

    def send_git_archive(repository, **kwargs)
      header(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))

      body ''
    end

    # Deprecated. Use `send_artifacts_entry` instead.
    def legacy_send_artifacts_entry(file, entry)
      header(*Gitlab::Workhorse.send_artifacts_entry(file, entry))

      body ''
    end

    def send_artifacts_entry(file, entry)
      header(*Gitlab::Workhorse.send_artifacts_entry(file, entry))
      header(*Gitlab::Workhorse.detect_content_type)

      body ''
    end

    # The Grape Error Middleware only has access to `env` but not `params` nor
    # `request`. We workaround this by defining methods that returns the right
    # values.
    def define_params_for_grape_middleware
      self.define_singleton_method(:request) { ActionDispatch::Request.new(env) }
      self.define_singleton_method(:params) { request.params.symbolize_keys }
    end

    # We could get a Grape or a standard Ruby exception. We should only report anything that
    # is clearly an error.
    def report_exception?(exception)
      return true unless exception.respond_to?(:status)

      exception.status == 500
    end

    def archived_param
      return 'only' if params[:archived]

      params[:archived]
    end

    def ip_address
      env["action_dispatch.remote_ip"].to_s || request.ip
    end

    def sanitize_id_param(id)
      id.present? ? id.to_i : nil
    end
  end
end

API::Helpers.prepend_mod_with('API::Helpers')

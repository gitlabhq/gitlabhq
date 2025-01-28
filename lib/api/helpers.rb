# frozen_string_literal: true

module API
  module Helpers
    include Gitlab::Allowable
    include Gitlab::Utils
    include Helpers::Caching
    include Helpers::Pagination
    include Helpers::PaginationStrategies
    include Gitlab::Ci::Artifacts::Logger
    include Gitlab::Utils::StrongMemoize
    include Gitlab::RackLoadBalancingHelpers

    SUDO_HEADER = "HTTP_SUDO"
    GITLAB_SHARED_SECRET_HEADER = "Gitlab-Shared-Secret"
    SUDO_PARAM = :sudo
    API_USER_ENV = 'gitlab.api.user'
    API_EXCEPTION_ENV = 'gitlab.api.exception'
    API_RESPONSE_STATUS_CODE = 'gitlab.api.response_status_code'
    INTEGER_ID_REGEX = /^-?\d+$/

    # ai_workflows scope is used by Duo Workflow which is an AI automation tool, requests authenticated by token with
    # this scope are audited to keep track of all actions done by Duo Workflow.
    TOKEN_SCOPES_TO_AUDIT = [:ai_workflows].freeze

    def logger
      API.logger
    end

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

      validate_and_save_access_token!(scopes: scopes_registered_for_endpoint) unless sudo?

      save_current_user_in_env(@current_user) if @current_user

      if @current_user
        load_balancer_stick_request(::ApplicationRecord, :user, @current_user.id)
        audit_request_with_token_scope(@current_user)
      end

      @current_user
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def set_current_organization(user: current_user)
      ::Current.organization = Gitlab::Current::Organization.new(
        params: {},
        user: user
      ).organization
    end

    def save_current_user_in_env(user)
      env[API_USER_ENV] = { user_id: user.id, username: user.username }
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

      projects = find_project_scopes

      if id.is_a?(Integer) || id =~ INTEGER_ID_REGEX
        projects.find_by(id: id)
      elsif id.include?("/")
        projects.find_by_full_path(id, follow_redirects: true)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Can be overriden by API endpoints
    def find_project_scopes
      Project.without_deleted.not_hidden
    end

    def find_project!(id)
      project = find_project(id)

      return forbidden!("This project's CI/CD job token cannot be used to authenticate with the container registry of a different project.") unless authorized_project_scope?(project)
      return not_found!('Project') if project.nil?

      unless can?(current_user, read_project_ability, project)
        return unauthorized! if authenticate_non_public?

        return handle_job_token_failure!(project)
      end

      authorize_job_token_policies!(project) && return

      if project_moved?(id, project)
        return not_allowed!('Non GET methods are not allowed for moved projects') unless request.get?

        return redirect!(url_with_project_id(project))
      end

      project
    end

    def authorize_job_token_policies!(project)
      forbidden!(job_token_policies_unauthorized_message(project)) unless job_token_policies_authorized?(project)
    end

    def read_project_ability
      :read_project
    end

    def authorized_project_scope?(project)
      return true unless job_token_authentication?
      return true unless route_authentication_setting[:job_token_scope] == :project

      current_authenticated_job.project == project
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_pipeline(id)
      return unless id

      if INTEGER_ID_REGEX.match?(id.to_s)
        ::Ci::Pipeline.find_by(id: id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_pipeline!(id)
      pipeline = find_pipeline(id)
      check_pipeline_access(pipeline)
    end

    def check_pipeline_access(pipeline)
      return forbidden! unless authorized_project_scope?(pipeline&.project)

      return pipeline if can?(current_user, :read_pipeline, pipeline)
      return unauthorized! if authenticate_non_public?

      not_found!('Pipeline')
    end

    def find_organization!(id)
      organization = ::Organizations::Organization.find_by_id(id)
      check_organization_access(organization)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_group(id, organization: nil)
      collection = organization.present? ? Group.in_organization(organization) : Group.all

      if INTEGER_ID_REGEX.match?(id.to_s)
        collection.find_by(id: id)
      else
        collection.find_by_full_path(id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_group!(id, organization: nil)
      group = find_group(id, organization: organization)
      # We need to ensure the namespace is in the context since
      # it's possible a method such as bypass_session! might log
      # a message before @group is set.
      ::Gitlab::ApplicationContext.push(namespace: group) if group
      check_group_access(group)
    end

    def find_group_by_full_path!(full_path)
      group = Group.find_by_full_path(full_path)
      check_group_access(group)
    end

    def check_group_access(group)
      return group if can?(current_user, :read_group, group)
      return unauthorized! if authenticate_non_public?

      not_found!('Group')
    end

    def check_namespace_access(namespace)
      return namespace if can?(current_user, :read_namespace_via_membership, namespace)

      not_found!('Namespace')
    end

    # find_namespace returns the namespace regardless of user access level on the namespace
    # rubocop: disable CodeReuse/ActiveRecord
    def find_namespace(id)
      if INTEGER_ID_REGEX.match?(id.to_s)
        # We need to stick to an up-to-date replica or primary db here in order to properly observe the namespace
        # recently created by GitlabSubscriptions::Trials::CreateService#create_group_flow.
        # See https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/9808
        ::Namespace.sticking.find_caught_up_replica(:namespace, id)

        Namespace.without_project_namespaces.find_by(id: id)
      else
        find_namespace_by_path(id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # find_namespace! returns the namespace if the current user can read the given namespace
    # Otherwise, returns a not_found! error
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
      unauthorized! unless Gitlab::Shell.verify_api_request(headers)
    end

    def authenticate_by_gitlab_shell_or_workhorse_token!
      return require_gitlab_workhorse! unless Gitlab::Shell.header_set?(headers)

      authenticate_by_gitlab_shell_token!
    end

    def authenticated_with_can_read_all_resources!
      authenticate!
      forbidden! unless current_user.can_read_all_resources?
    end

    def authenticated_as_admin!
      authenticate!
      forbidden! unless current_user.can_admin_all_resources?
    end

    def authorize_read_application_statistics!
      authenticated_as_admin!
    end

    def authorize!(action, subject = :global, reason = nil)
      forbidden!(reason) unless can?(current_user, action, subject)
    end

    def authorize_any!(abilities, subject = :global, reason = nil)
      forbidden!(reason) unless can_any?(current_user, abilities, subject)
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

    def authorize_admin_integrations
      authorize! :admin_integrations, user_project
    end

    def authorize_admin_group
      authorize! :admin_group, user_group
    end

    def authorize_admin_member_role_on_group!
      authorize! :admin_member_role, user_group
    end

    def authorize_admin_member_role_on_instance!
      authorize! :admin_member_role
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

    def authorize_cancel_builds!
      authorize! :cancel_build, user_project
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
      not_found! unless ::Gitlab::Pages.enabled?
    end

    def require_pages_config_enabled!
      not_found! unless Gitlab.config.pages.enabled
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

    def order_options_with_tie_breaker(override_created_at: true)
      order_by = if params[:order_by] == 'created_at' && override_created_at
                   'id'
                 else
                   params[:order_by]
                 end

      order_options = { order_by => params[:sort] }
      order_options['id'] ||= params[:sort] || 'asc'
      order_options
    end

    # An error is raised to interrupt user's request and redirect them to the right route.
    # The error! helper behaves similarly, but it cannot be used because it formats the
    # response message.
    def redirect!(location_url)
      raise ::API::API::MovedPermanentlyError, location_url
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

    def too_many_requests!(message = nil, retry_after: 1.minute)
      header['Retry-After'] = retry_after.to_i if retry_after

      render_api_error!(message || '429 Too Many Requests', 429)
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

    def accepted!(message = '202 Accepted')
      render_api_error!(message, 202)
    end

    def render_validation_error!(models, status = 400)
      models = Array(models)

      errors = models.map { |m| model_errors(m) }.filter(&:present?)
      messages = errors.map(&:messages)
      messages = messages.count == 1 ? messages.first : messages.join(" ")

      render_api_error!(messages || '400 Bad Request', status) if errors.any?
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

    def present_disk_file!(path, filename, content_type: nil, extra_response_headers: {})
      filename ||= File.basename(path)
      extra_response_headers.compact_blank.each { |k, v| header[k] = v }
      header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: filename)
      header['Content-Transfer-Encoding'] = 'binary'
      content_type(content_type || 'application/octet-stream')

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

    # Return back the given file depending on the object storage configuration.
    # For disabled mode, the disk file is returned.
    # For enabled mode, the response depends on the direct download support:
    #   * direct download supported by the uploader class: a redirect to the file signed url is returned.
    #   * direct download not supported: a workhorse send_url response is returned.
    #
    # Params:
    # @file the carrierwave file.
    # @supports_direct_download set to false to force a workhorse send_url response. true by default.
    # @content_disposition controls the Content-Disposition response header. nil by default. Forced to attachment for object storage disabled mode.
    # @content_type controls the Content-Type response header. By default, it will rely on the 'application/octet-stream' value or the content type detected by carrierwave.
    # @extra_response_headers. Set additional response headers. Not used in the direct download supported case.
    def present_carrierwave_file!(file, supports_direct_download: true, content_disposition: nil, content_type: nil, extra_response_headers: {})
      return not_found! unless file&.exists?

      if content_disposition
        response_disposition = ActionDispatch::Http::ContentDisposition.format(disposition: content_disposition, filename: file.filename)
      end

      if file.file_storage?
        present_disk_file!(file.path, file.filename, content_type: content_type, extra_response_headers: extra_response_headers)
      elsif supports_direct_download && file.direct_download_enabled?
        return redirect(ObjectStorage::S3.signed_head_url(file)) if request.head? && file.fog_credentials[:provider] == 'AWS'

        redirect_params = {}
        if content_disposition
          redirect_params[:query] = { 'response-content-disposition' => response_disposition, 'response-content-type' => content_type || file.content_type }
        end

        file_url = ObjectStorage::CDN::FileUrl.new(file: file, ip_address: ip_address, redirect_params: redirect_params)
        redirect(file_url.url)
      else
        response_headers = extra_response_headers.merge('Content-Type' => content_type, 'Content-Disposition' => response_disposition).compact_blank

        header(*Gitlab::Workhorse.send_url(file.url, response_headers: response_headers))
        status :ok
        body '' # to avoid an error from API::APIGuard::ResponseCoercerMiddleware
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

    def track_event(event_name, user:, send_snowplow_event: true, namespace_id: nil, project_id: nil, additional_properties: {})
      return unless user.present?

      namespace = Namespace.find(namespace_id) if namespace_id
      project = Project.find(project_id) if project_id

      Gitlab::InternalEvents.track_event(
        event_name,
        send_snowplow_event: send_snowplow_event,
        additional_properties: additional_properties,
        user: user,
        namespace: namespace,
        project: project
      )
    rescue Gitlab::Tracking::EventValidator::UnknownEventError => e
      Gitlab::ErrorTracking.track_exception(e, event_name: event_name)

      # We want to keep the error silent on production to keep the behavior
      # consistent with StandardError rescue
      unprocessable_entity!(e.message) if Gitlab.dev_or_test_env?
    rescue StandardError => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_name: event_name)
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
      finder_params[:include_pending_delete] = declared_params[:include_pending_delete] if declared_params[:include_pending_delete]
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

    def audit_request_with_token_scope(user)
      token_info = ::Current.token_info
      return unless token_info
      return unless TOKEN_SCOPES_TO_AUDIT.intersect?(Array.wrap(token_info[:token_scopes]))

      context = {
        name: 'api_request_access_with_scope',
        author: user,
        scope: user,
        target: ::Gitlab::Audit::NullTarget.new,
        message: "API request with token scopes #{token_info[:token_scopes]} - #{request.request_method} #{request.path}",
        additional_details: {
          request: request.path,
          method: request.request_method,
          token_scopes: token_info[:token_scopes]
        }
      }

      ::Gitlab::Audit::Auditor.audit(context)
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def initial_current_user
      return @initial_current_user if defined?(@initial_current_user)

      begin
        @initial_current_user = Gitlab::Auth::UniqueIpsLimiter.limit_user! { find_current_user! }
      rescue Gitlab::Auth::UnauthorizedError
        unauthorized!

        # Explicitly return `nil`, otherwise an instance of `Rack::Response` is returned when reporting an error
        nil
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
        forbidden!('Must be authenticated using an OAuth or personal access token to use sudo')
      end

      validate_and_save_access_token!(scopes: [:sudo])

      sudoed_user = find_user(sudo_identifier)
      not_found!("User with ID or username '#{sudo_identifier}'") unless sudoed_user

      @current_user = sudoed_user # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def sudo_identifier
      @sudo_identifier ||= params[SUDO_PARAM] || env[SUDO_HEADER]
    end

    def check_organization_access(organization)
      return organization if can?(current_user, :read_organization, organization)

      not_found!('Organization')
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

      # Some browsers ignore content type when filename has an xhtml extension
      # We remove the extensions to prevent the contents from being displayed inline
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/458236
      filename = blob.name&.ends_with?('.xhtml') ? blob.name.split('.')[0] : blob.name
      header['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: filename)

      # Let Workhorse examine the content and determine the better content disposition
      header[Gitlab::Workhorse::DETECT_HEADER] = "true"

      header(*Gitlab::Workhorse.send_git_blob(repository, blob))

      body ''
    end

    def send_git_diff(repository, diff_refs)
      header(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))

      headers['Content-Disposition'] = 'inline'

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

    def project_moved?(id, project)
      return false unless id.is_a?(String) && id.include?('/')
      return false if project.blank? || project.full_path.casecmp?(id)
      return false unless params[:id] == id

      true
    end

    def url_with_project_id(project)
      new_params = params.merge(id: project.id.to_s).transform_values { |v| v.is_a?(String) ? CGI.escape(v) : v }
      new_path = GrapePathHelpers::DecoratedRoute.new(route).path_segments_with_values(new_params).join('/')

      Rack::Request.new(env).tap do |r|
        r.path_info = "/#{new_path}"
      end.url
    end

    def handle_job_token_failure!(project)
      if current_user&.from_ci_job_token? && current_user&.ci_job_token_scope
        source_project = current_user.ci_job_token_scope.current_project
        error_message = format("Authentication by CI/CD job token not allowed from %{source_project_path} to %{target_project_path}.", source_project_path: source_project.path, target_project_path: project.path)

        forbidden!(error_message)
      else
        not_found!('Project')
      end
    end

    def job_token_policies_authorized?(project)
      return true unless current_user&.from_ci_job_token?
      return true unless Feature.enabled?(:add_policies_to_ci_job_token, project)
      return true if skip_job_token_policies?

      current_user.ci_job_token_scope.policies_allowed?(project, job_token_policies)
    end

    def job_token_policies_unauthorized_message(project)
      policies = job_token_policies
      case policies.size
      when 0
        'This action is unauthorized for CI/CD job tokens.'
      when 1
        format("Insufficient permissions to access this resource in project %{project}. " \
          "The following token permission is required: %{policy}.",
          project: project.path, policy: policies[0])
      else
        format("Insufficient permissions to access this resource in project %{project}. " \
          "The following token permissions are required: %{policies}.",
          project: project.path, policies: policies.to_sentence)
      end
    end

    def job_token_policies
      return [] unless respond_to?(:route_setting)

      Array(route_setting(:authorization).try(:fetch, :job_token_policies, nil))
    end

    def skip_job_token_policies?
      return false unless respond_to?(:route_setting)

      route_setting(:authorization).try(:fetch, :skip_job_token_policies, false)
    end
  end
end

API::Helpers.prepend_mod_with('API::Helpers')

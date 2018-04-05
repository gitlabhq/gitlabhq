module API
  module Helpers
    include Gitlab::Utils
    include Helpers::Pagination

    SUDO_HEADER = "HTTP_SUDO".freeze
    SUDO_PARAM = :sudo
    API_USER_ENV = 'gitlab.api.user'.freeze

    def declared_params(options = {})
      options = { include_parent_namespaces: false }.merge(options)
      declared(params, options).to_h.symbolize_keys
    end

    def check_unmodified_since!(last_modified)
      if_unmodified_since = Time.parse(headers['If-Unmodified-Since']) rescue nil

      if if_unmodified_since && last_modified && last_modified > if_unmodified_since
        render_api_error!('412 Precondition Failed', 412)
      end
    end

    def destroy_conditionally!(resource, last_updated: nil)
      last_updated ||= resource.updated_at

      check_unmodified_since!(last_updated)

      status 204

      if block_given?
        yield resource
      else
        resource.destroy
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

      @current_user
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def save_current_user_in_env(user)
      env[API_USER_ENV] = { user_id: user.id, username: user.username }
    end

    def sudo?
      initial_current_user != current_user
    end

    def user_namespace
      @user_namespace ||= find_namespace!(params[:id])
    end

    def user_group
      @group ||= find_group!(params[:id])
    end

    def user_project
      @project ||= find_project!(params[:id])
    end

    def wiki_page
      page = ProjectWiki.new(user_project, current_user).find_page(params[:slug])

      page || not_found!('Wiki Page')
    end

    def available_labels_for(label_parent)
      search_params = { include_ancestor_groups: true }

      if label_parent.is_a?(Project)
        search_params[:project_id] = label_parent.id
      else
        search_params.merge!(group_id: label_parent.id, only_group_labels: true)
      end

      LabelsFinder.new(current_user, search_params).execute
    end

    def find_user(id)
      if id =~ /^\d+$/
        User.find_by(id: id)
      else
        User.find_by(username: id)
      end
    end

    def find_project(id)
      if id =~ /^\d+$/
        Project.find_by(id: id)
      else
        Project.find_by_full_path(id)
      end
    end

    def find_project!(id)
      project = find_project(id)

      if can?(current_user, :read_project, project)
        project
      else
        not_found!('Project')
      end
    end

    def find_group(id)
      if id.to_s =~ /^\d+$/
        Group.find_by(id: id)
      else
        Group.find_by_full_path(id)
      end
    end

    def find_group!(id)
      group = find_group(id)

      if can?(current_user, :read_group, group)
        group
      else
        not_found!('Group')
      end
    end

    def find_namespace(id)
      if id.to_s =~ /^\d+$/
        Namespace.find_by(id: id)
      else
        Namespace.find_by_full_path(id)
      end
    end

    def find_namespace!(id)
      namespace = find_namespace(id)

      if can?(current_user, :read_namespace, namespace)
        namespace
      else
        not_found!('Namespace')
      end
    end

    def find_project_label(id)
      labels = available_labels_for(user_project)
      label = labels.find_by_id(id) || labels.find_by_title(id)

      label || not_found!('Label')
    end

    def find_project_issue(iid)
      IssuesFinder.new(current_user, project_id: user_project.id).find_by!(iid: iid)
    end

    def find_project_merge_request(iid)
      MergeRequestsFinder.new(current_user, project_id: user_project.id).find_by!(iid: iid)
    end

    def find_project_snippet(id)
      finder_params = { project: user_project }
      SnippetsFinder.new(current_user, finder_params).find(id)
    end

    def find_merge_request_with_access(iid, access_level = :read_merge_request)
      merge_request = user_project.merge_requests.find_by!(iid: iid)
      authorize! access_level, merge_request
      merge_request
    end

    def find_build!(id)
      user_project.builds.find(id.to_i)
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authenticate_non_get!
      authenticate! unless %w[GET HEAD].include?(route.request_method)
    end

    def authenticate_by_gitlab_shell_token!
      input = params['secret_token'].try(:chomp)
      unless Devise.secure_compare(secret_token, input)
        unauthorized!
      end
    end

    def authenticated_with_full_private_access!
      authenticate!
      forbidden! unless current_user.full_private_access?
    end

    def authenticated_as_admin!
      authenticate!
      forbidden! unless current_user.admin?
    end

    def authorize!(action, subject = :global)
      forbidden! unless can?(current_user, action, subject)
    end

    def authorize_push_project
      authorize! :push_code, user_project
    end

    def authorize_admin_project
      authorize! :admin_project, user_project
    end

    def authorize_read_builds!
      authorize! :read_build, user_project
    end

    def authorize_update_builds!
      authorize! :update_build, user_project
    end

    def require_gitlab_workhorse!
      unless env['HTTP_GITLAB_WORKHORSE'].present?
        forbidden!('Request should be executed via GitLab Workhorse')
      end
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
        bad_request!(key) unless params[key].present?
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
      ActionController::Parameters.new(attrs).permit!
    end

    def filter_by_iid(items, iid)
      items.where(iid: iid)
    end

    def filter_by_search(items, text)
      items.search(text)
    end

    # error helpers

    def forbidden!(reason = nil)
      message = ['403 Forbidden']
      message << " - #{reason}" if reason
      render_api_error!(message.join(' '), 403)
    end

    def bad_request!(attribute)
      message = ["400 (Bad request)"]
      message << "\"" + attribute.to_s + "\" not given" if attribute
      render_api_error!(message.join(' '), 400)
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      render_api_error!(message.join(' '), 404)
    end

    def unauthorized!
      render_api_error!('401 Unauthorized', 401)
    end

    def not_allowed!
      render_api_error!('405 Method Not Allowed', 405)
    end

    def conflict!(message = nil)
      render_api_error!(message || '409 Conflict', 409)
    end

    def file_to_large!
      render_api_error!('413 Request Entity Too Large', 413)
    end

    def not_modified!
      render_api_error!('304 Not Modified', 304)
    end

    def no_content!
      render_api_error!('204 No Content', 204)
    end

    def accepted!
      render_api_error!('202 Accepted', 202)
    end

    def render_validation_error!(model)
      if model.errors.any?
        render_api_error!(model.errors.messages || '400 Bad Request', 400)
      end
    end

    def render_spam_error!
      render_api_error!({ error: 'Spam detected' }, 400)
    end

    def render_api_error!(message, status)
      error!({ 'message' => message }, status, header)
    end

    def handle_api_exception(exception)
      if sentry_enabled? && report_exception?(exception)
        define_params_for_grape_middleware
        sentry_context
        Raven.capture_exception(exception, extra: params)
      end

      # lifted from https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb#L60
      trace = exception.backtrace

      message = "\n#{exception.class} (#{exception.message}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << trace.join("\n  ")

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

    def reorder_projects(projects)
      projects.reorder(params[:order_by] => params[:sort])
    end

    def project_finder_params
      finder_params = {}
      finder_params[:owned] = true if params[:owned].present?
      finder_params[:non_public] = true if params[:membership].present?
      finder_params[:starred] = true if params[:starred].present?
      finder_params[:visibility_level] = Gitlab::VisibilityLevel.level_value(params[:visibility]) if params[:visibility]
      finder_params[:archived] = params[:archived]
      finder_params[:search] = params[:search] if params[:search]
      finder_params[:user] = params.delete(:user) if params[:user]
      finder_params[:custom_attributes] = params[:custom_attributes] if params[:custom_attributes]
      finder_params
    end

    # file helpers

    def present_disk_file!(path, filename, content_type = 'application/octet-stream')
      filename ||= File.basename(path)
      header['Content-Disposition'] = "attachment; filename=#{filename}"
      header['Content-Transfer-Encoding'] = 'binary'
      content_type content_type

      # Support download acceleration
      case headers['X-Sendfile-Type']
      when 'X-Sendfile'
        header['X-Sendfile'] = path
        body
      else
        file path
      end
    end

    def present_carrierwave_file!(file, supports_direct_download: true)
      return not_found! unless file.exists?

      if file.file_storage?
        present_disk_file!(file.path, file.filename)
      elsif supports_direct_download && file.class.direct_download_enabled?
        redirect(file.url)
      else
        header(*Gitlab::Workhorse.send_url(file.url))
        status :ok
        body
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

      unless initial_current_user.admin?
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

    def send_git_blob(repository, blob)
      env['api.format'] = :txt
      content_type 'text/plain'
      header(*Gitlab::Workhorse.send_git_blob(repository, blob))
    end

    def send_git_archive(repository, ref:, format:)
      header(*Gitlab::Workhorse.send_git_archive(repository, ref: ref, format: format))
    end

    def send_artifacts_entry(build, entry)
      header(*Gitlab::Workhorse.send_artifacts_entry(build, entry))
    end

    # The Grape Error Middleware only has access to `env` but not `params` nor
    # `request`. We workaround this by defining methods that returns the right
    # values.
    def define_params_for_grape_middleware
      self.define_singleton_method(:request) { Rack::Request.new(env) }
      self.define_singleton_method(:params) { request.params.symbolize_keys }
    end

    # We could get a Grape or a standard Ruby exception. We should only report anything that
    # is clearly an error.
    def report_exception?(exception)
      return true unless exception.respond_to?(:status)

      exception.status == 500
    end
  end
end

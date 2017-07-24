module API
  module Helpers
    prepend EE::API::Helpers

    include Gitlab::Utils
    include Helpers::Pagination

    SUDO_HEADER = "HTTP_SUDO".freeze
    SUDO_PARAM = :sudo

    def declared_params(options = {})
      options = { include_parent_namespaces: false }.merge(options)
      declared(params, options).to_h.symbolize_keys
    end

    def current_user
      return @current_user if defined?(@current_user)

      @current_user = initial_current_user

      sudo!

      @current_user
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

    def available_labels
      @available_labels ||= LabelsFinder.new(current_user, project_id: user_project.id).execute
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
      if id =~ /^\d+$/
        Group.find_by(id: id)
      else
        Group.find_by_full_path(id)
      end
    end

    def find_namespace(id)
      if id =~ /^\d+$/
        Namespace.find_by(id: id)
      else
        Namespace.find_by_full_path(id)
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

    def find_project_label(id)
      label = available_labels.find_by_id(id) || available_labels.find_by_title(id)
      label || not_found!('Label')
    end

    def find_project_issue(iid, project_id = nil)
      project = project_id ? find_project!(project_id) : user_project
      IssuesFinder.new(current_user, project_id: project.id).find_by!(iid: iid)
    end

    def find_project_merge_request(iid)
      MergeRequestsFinder.new(current_user, project_id: user_project.id).find_by!(iid: iid)
    end

    def find_project_snippet(id)
      finder_params = { project: user_project }
      SnippetsFinder.new(current_user, finder_params).execute.find(id)
    end

    def find_merge_request_with_access(iid, access_level = :read_merge_request)
      merge_request = user_project.merge_requests.find_by!(iid: iid)
      authorize! access_level, merge_request
      merge_request
    end

    def authenticate!
      unauthorized! unless current_user && can?(initial_current_user, :access_api)
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

    def authenticate_by_gitlab_geo_token!
      token = headers['X-Gitlab-Token'].try(:chomp)
      unless token && Devise.secure_compare(geo_token, token)
        unauthorized!
      end
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

    def require_gitlab_workhorse!
      unless env['HTTP_GITLAB_WORKHORSE'].present?
        forbidden!('Request should be executed via GitLab Workhorse')
      end
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
      message << "\"" + attribute.to_s + "\" not given"
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
        Raven.capture_exception(exception)
      end

      # lifted from https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb#L60
      trace = exception.backtrace

      message = "\n#{exception.class} (#{exception.message}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << trace.join("\n  ")

      API.logger.add Logger::FATAL, message
      rack_response({ 'message' => '500 Internal Server Error' }.to_json, 500)
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
      finder_params
    end

    # file helpers

    def uploaded_file(field, uploads_path)
      if params[field]
        bad_request!("#{field} is not a file") unless params[field].respond_to?(:filename)
        return params[field]
      end

      return nil unless params["#{field}.path"] && params["#{field}.name"]

      # sanitize file paths
      # this requires all paths to exist
      required_attributes! %W(#{field}.path)
      uploads_path = File.realpath(uploads_path)
      file_path = File.realpath(params["#{field}.path"])
      bad_request!('Bad file path') unless file_path.start_with?(uploads_path)

      UploadedFile.new(
        file_path,
        params["#{field}.name"],
        params["#{field}.type"] || 'application/octet-stream'
      )
    end

    def present_file!(path, filename, content_type = 'application/octet-stream')
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

    def present_artifacts!(artifacts_file)
      return not_found! unless artifacts_file.exists?

      if artifacts_file.file_storage?
        present_file!(artifacts_file.path, artifacts_file.filename)
      else
        redirect(artifacts_file.url)
      end
    end

    private

    def private_token
      params[APIGuard::PRIVATE_TOKEN_PARAM] || env[APIGuard::PRIVATE_TOKEN_HEADER]
    end

    def warden
      env['warden']
    end

    # Check the Rails session for valid authentication details
    #
    # Until CSRF protection is added to the API, disallow this method for
    # state-changing endpoints
    def find_user_from_warden
      warden.try(:authenticate) if %w[GET HEAD].include?(env['REQUEST_METHOD'])
    end

    def initial_current_user
      return @initial_current_user if defined?(@initial_current_user)
      Gitlab::Auth::UniqueIpsLimiter.limit_user! do
        @initial_current_user ||= find_user_by_private_token(scopes: scopes_registered_for_endpoint)
        @initial_current_user ||= doorkeeper_guard(scopes: scopes_registered_for_endpoint)
        @initial_current_user ||= find_user_from_warden

        unless @initial_current_user && Gitlab::UserAccess.new(@initial_current_user).allowed?
          @initial_current_user = nil
        end

        @initial_current_user
      end
    end

    def sudo!
      return unless sudo_identifier
      return unless initial_current_user

      unless initial_current_user.admin?
        forbidden!('Must be admin to use sudo')
      end

      # Only private tokens should be used for the SUDO feature
      unless private_token == initial_current_user.private_token
        forbidden!('Private token must be specified in order to use sudo')
      end

      sudoed_user = find_user(sudo_identifier)

      if sudoed_user
        @current_user = sudoed_user
      else
        not_found!("No user id or username for: #{sudo_identifier}")
      end
    end

    def sudo_identifier
      @sudo_identifier ||= params[SUDO_PARAM] || env[SUDO_HEADER]
    end

    def secret_token
      Gitlab::Shell.secret_token
    end

    def geo_token
      Gitlab::Geo.current_node.system_hook.token
    end

    def send_git_blob(repository, blob)
      env['api.format'] = :txt
      content_type 'text/plain'
      header(*Gitlab::Workhorse.send_git_blob(repository, blob))
    end

    def send_git_archive(repository, ref:, format:)
      header(*Gitlab::Workhorse.send_git_archive(repository, ref: ref, format: format))
    end

    # The Grape Error Middleware only has access to env but no params. We workaround this by
    # defining a method that returns the right value.
    def define_params_for_grape_middleware
      self.define_singleton_method(:params) { Rack::Request.new(env).params.symbolize_keys }
    end

    # We could get a Grape or a standard Ruby exception. We should only report anything that
    # is clearly an error.
    def report_exception?(exception)
      return true unless exception.respond_to?(:status)

      exception.status == 500
    end

    # An array of scopes that were registered (using `allow_access_with_scope`)
    # for the current endpoint class. It also returns scopes registered on
    # `API::API`, since these are meant to apply to all API routes.
    def scopes_registered_for_endpoint
      @scopes_registered_for_endpoint ||=
        begin
          endpoint_classes = [options[:for].presence, ::API::API].compact
          endpoint_classes.reduce([]) do |memo, endpoint|
            if endpoint.respond_to?(:allowed_scopes)
              memo.concat(endpoint.allowed_scopes)
            else
              memo
            end
          end
        end
    end
  end
end

module API
  module Helpers
    include Gitlab::Utils

    PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
    PRIVATE_TOKEN_PARAM = :private_token
    SUDO_HEADER = "HTTP_SUDO"
    SUDO_PARAM = :sudo

    def private_token
      params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]
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

    def declared_params(options = {})
      options = { include_parent_namespaces: false }.merge(options)
      declared(params, options).to_h.symbolize_keys
    end

    def find_user_by_private_token
      token = private_token
      return nil unless token.present?

      User.find_by_authentication_token(token) || User.find_by_personal_access_token(token)
    end

    def current_user
      @current_user ||= find_user_by_private_token
      @current_user ||= doorkeeper_guard
      @current_user ||= find_user_from_warden

      unless @current_user && Gitlab::UserAccess.new(@current_user).allowed?
        return nil
      end

      identifier = sudo_identifier()

      # If the sudo is the current user do nothing
      if identifier && !(@current_user.id == identifier || @current_user.username == identifier)
        forbidden!('Must be admin to use sudo') unless @current_user.is_admin?
        @current_user = User.by_username_or_id(identifier)
        not_found!("No user id or username for: #{identifier}") if @current_user.nil?
      end

      @current_user
    end

    def sudo_identifier
      identifier ||= params[SUDO_PARAM] || env[SUDO_HEADER]

      # Regex for integers
      if !!(identifier =~ /\A[0-9]+\z/)
        identifier.to_i
      else
        identifier
      end
    end

    def user_project
      @project ||= find_project(params[:id])
    end

    def available_labels
      @available_labels ||= LabelsFinder.new(current_user, project_id: user_project.id).execute
    end

    def find_project(id)
      project = Project.find_with_namespace(id) || Project.find_by(id: id)

      if can?(current_user, :read_project, project)
        project
      else
        not_found!('Project')
      end
    end

    def project_service(project = user_project)
      @project_service ||= project.find_or_initialize_service(params[:service_slug].underscore)
      @project_service || not_found!("Service")
    end

    def service_attributes
      @service_attributes ||= project_service.fields.inject([]) do |arr, hash|
        arr << hash[:name].to_sym
      end
    end

    def find_group(id)
      group = Group.find_by(path: id) || Group.find_by(id: id)

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

    def find_project_issue(id)
      IssuesFinder.new(current_user, project_id: user_project.id).find(id)
    end

    def paginate(relation)
      relation.page(params[:page]).per(params[:per_page].to_i).tap do |data|
        add_pagination_headers(data)
      end
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authenticate_by_gitlab_shell_token!
      input = params['secret_token'].try(:chomp)
      unless Devise.secure_compare(secret_token, input)
        unauthorized!
      end
    end

    def authenticated_as_admin!
      forbidden! unless current_user.is_admin?
    end

    def authorize!(action, subject = nil)
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

    def can?(object, action, subject)
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
        if params_hash[key].present? or (params_hash.has_key?(key) and params_hash[key] == false)
          attrs[key] = params_hash[key]
        end
      end
      ActionController::Parameters.new(attrs).permit!
    end

    # Checks the occurrences of datetime attributes, each attribute if present in the params hash must be in ISO 8601
    # format (YYYY-MM-DDTHH:MM:SSZ) or a Bad Request error is invoked.
    #
    # Parameters:
    #   keys (required) - An array consisting of elements that must be parseable as dates from the params hash
    def datetime_attributes!(*keys)
      keys.each do |key|
        begin
          params[key] = Time.xmlschema(params[key]) if params[key].present?
        rescue ArgumentError
          message = "\"" + key.to_s + "\" must be a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ"
          render_api_error!(message, 400)
        end
      end
    end

    def issuable_order_by
      if params["order_by"] == 'updated_at'
        'updated_at'
      else
        'created_at'
      end
    end

    def issuable_sort
      if params["sort"] == 'asc'
        :asc
      else
        :desc
      end
    end

    def filter_by_iid(items, iid)
      items.where(iid: iid)
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

    def render_validation_error!(model)
      if model.errors.any?
        render_api_error!(model.errors.messages || '400 Bad Request', 400)
      end
    end

    def render_api_error!(message, status)
      error!({ 'message' => message }, status)
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

    # Projects helpers

    def filter_projects(projects)
      # If the archived parameter is passed, limit results accordingly
      if params[:archived].present?
        projects = projects.where(archived: to_boolean(params[:archived]))
      end

      if params[:search].present?
        projects = projects.search(params[:search])
      end

      if params[:visibility].present?
        projects = projects.search_by_visibility(params[:visibility])
      end

      projects.reorder(project_order_by => project_sort)
    end

    def project_order_by
      order_fields = %w(id name path created_at updated_at last_activity_at)

      if order_fields.include?(params['order_by'])
        params['order_by']
      else
        'created_at'
      end
    end

    def project_sort
      if params["sort"] == 'asc'
        :asc
      else
        :desc
      end
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
        params["#{field}.type"] || 'application/octet-stream',
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
        file FileStreamer.new(path)
      end
    end

    private

    def add_pagination_headers(paginated_data)
      header 'X-Total',       paginated_data.total_count.to_s
      header 'X-Total-Pages', paginated_data.total_pages.to_s
      header 'X-Per-Page',    paginated_data.limit_value.to_s
      header 'X-Page',        paginated_data.current_page.to_s
      header 'X-Next-Page',   paginated_data.next_page.to_s
      header 'X-Prev-Page',   paginated_data.prev_page.to_s
      header 'Link',          pagination_links(paginated_data)
    end

    def pagination_links(paginated_data)
      request_url = request.url.split('?').first
      request_params = params.clone
      request_params[:per_page] = paginated_data.limit_value

      links = []

      request_params[:page] = paginated_data.current_page - 1
      links << %(<#{request_url}?#{request_params.to_query}>; rel="prev") unless paginated_data.first_page?

      request_params[:page] = paginated_data.current_page + 1
      links << %(<#{request_url}?#{request_params.to_query}>; rel="next") unless paginated_data.last_page?

      request_params[:page] = 1
      links << %(<#{request_url}?#{request_params.to_query}>; rel="first")

      request_params[:page] = paginated_data.total_pages
      links << %(<#{request_url}?#{request_params.to_query}>; rel="last")

      links.join(', ')
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

    def issue_entity(project)
      if project.has_external_issue_tracker?
        Entities::ExternalIssue
      else
        Entities::Issue
      end
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
  end
end

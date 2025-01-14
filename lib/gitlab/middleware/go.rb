# frozen_string_literal: true

# A middleware that returns a Go HTML document if the go-get=1 query string is present
module Gitlab
  module Middleware
    class Go
      include ActionView::Helpers::TagHelper
      include ActionController::HttpAuthentication::Basic

      PROJECT_PATH_REGEX = %r{\A(#{Gitlab::PathRegex.full_namespace_route_regex}/#{Gitlab::PathRegex.project_route_regex})/}

      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        return handle_go_get_request(request) if go_get_request?(request)

        @app.call(env)

      rescue Gitlab::Auth::IpBlocked => e
        Gitlab::AuthLogger.error(
          message: 'Rack_Attack',
          status: 403,
          env: :blocklist,
          remote_ip: request.ip,
          request_method: request.request_method,
          path: request.filtered_path
        )
        Rack::Response.new(e.message, 403).finish
      rescue Gitlab::Auth::MissingPersonalAccessTokenError
        not_found_response
      end

      private

      # not_found_response returns a message that the go cli toolchain displays directly.
      def not_found_response
        go_help_page_url = Rails.application.routes.url_helpers.help_page_url('user/project/use_project_as_go_package.md')
        not_found_message = "Go package not found or access denied. If you are trying to access a private project, ensure your ~/.netrc file has credentials so the go toolchain can authenticate. See #{go_help_page_url} for details."

        [404, { 'Content-Type' => 'text/plain' }, [not_found_message]]
      end

      # handle_go_get_request responds to `go get` requests by either returning a successful 200
      # response with meta tags as described in https://go.dev/ref/mod, or a 404 response with a
      # message that the go toolchain will display.
      #
      # The go toolchain authenticates using basic auth. When credentials are not present, a
      # successful response is always returned as if a project exists (using a two-segment path
      # like `namespace/project`) in order to prevent leaking information about the existence of
      # private projects, and to maintain backwards compatibility for users who have not set up
      # authentication for their go toolchain.
      def handle_go_get_request(request)
        path_info = request.env["PATH_INFO"].delete_prefix('/')
        project = project_for_path(path_info)

        if project && can_read_project?(request, project)
          return not_found_response unless project.repository_exists?

          create_go_get_html_response(project.full_path)
        elsif request.authorization.present?
          not_found_response
        else
          path_segments = path_info.split('/')
          return not_found_response unless path_segments.length >= 2

          two_segment_path = path_segments.first(2).join('/')

          create_go_get_html_response(two_segment_path)
        end
      end

      def go_get_request?(request)
        request["go-get"].to_i == 1 && request.env["PATH_INFO"].present?
      end

      def get_repo_url(project_full_path)
        return ssh_url(project_full_path) if Gitlab::CurrentSettings.enabled_git_access_protocol == 'ssh'

        "#{http_url(project_full_path)}.git"
      end

      # create_go_get_html_response creates a HTML document for go get with the expected meta tags.
      def create_go_get_html_response(project_full_path)
        root_path = get_root_path(project_full_path)
        repo_url = get_repo_url(project_full_path)

        go_import_meta_tag = tag.meta(name: 'go-import', content: "#{root_path} git #{repo_url}")
        head_tag = content_tag :head, go_import_meta_tag
        body_tag = content_tag :body, "go get #{root_path}"
        html = content_tag :html, head_tag + body_tag

        response = Rack::Response.new(html, 200, { 'Content-Type' => 'text/html' })
        response.finish
      end

      # get_root_path returns a root path based on the instance URL
      # that includes a relative part of URL if it was set
      def get_root_path(project_full_path)
        http_url(project_full_path).gsub(%r{\Ahttps?://}, '')
      end

      # http_url returns a direct link to the project
      def http_url(project_full_path)
        Gitlab::Utils.append_path(Gitlab.config.gitlab.url, project_full_path)
      end

      # project_for_path searches for a project based on the path_info
      def project_for_path(path_info)
        project_path_match = "#{path_info}/".match(PROJECT_PATH_REGEX)
        return unless project_path_match

        path = project_path_match[1]

        # A go package path may use a subdirectory. For example a valid package path
        # is `example.com/namespace/group/group/project/path1/path2/path3`.
        # So we need to find all potential gitlab project paths from the package path.
        # For more details on package paths see https://go.dev/ref/mod.

        # Apply maximum upper limit to number of segments (group + 20 subgroups + project = 22 elements)
        path_segments = path.split('/').take(22) # rubocop: disable CodeReuse/ActiveRecord -- not an active record operation

        project_paths = []
        begin
          project_paths << path_segments.join('/')
          path_segments.pop
        end while path_segments.length >= 2

        project = Project.where_full_path_in(project_paths).first
        return project if project

        # It's possible that the project was transferred and has a redirect
        redirect = RedirectRoute.for_source_type(Project).by_paths(project_paths).first
        return redirect.source if redirect

        nil
      end

      # can_read_project? checks if the request's credentials have read access to the project
      def can_read_project?(request, project)
        return true if project.public?
        return false unless has_basic_credentials?(request)

        login, password = user_name_and_password(request)
        auth_result = Gitlab::Auth.find_for_git_client(login, password, project: project, request: request)

        auth_result.success? &&
          auth_result.authentication_abilities_include?(:read_project) &&
          auth_result.can_perform_action_on_project?(:read_project, project)
      end

      def ssh_url(path)
        shell = Gitlab.config.gitlab_shell
        user = "#{shell.ssh_user}@" unless shell.ssh_user.empty?
        port = ":#{shell.ssh_port}" unless shell.ssh_port == 22
        "ssh://#{user}#{shell.ssh_host}#{port}/#{path}.git"
      end
    end
  end
end

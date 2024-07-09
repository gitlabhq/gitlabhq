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

        if Feature.enabled?(:not_found_response_for_go_get, Feature.current_request)
          return handle_go_get_request(request) if go_get_request?(request)

          @app.call(env)
        else
          render_go_doc(request) || @app.call(env)
        end

      rescue Gitlab::Auth::IpBlocked => e
        Gitlab::AuthLogger.error(
          message: 'Rack_Attack',
          status: 403,
          env: :blocklist,
          remote_ip: request.ip,
          request_method: request.request_method,
          path: request.fullpath
        )
        Rack::Response.new(e.message, 403).finish
      rescue Gitlab::Auth::MissingPersonalAccessTokenError
        Rack::Response.new('', 401).finish
      end

      private

      # not_found_response returns a message that the go cli toolchain displays directly.
      def not_found_response
        go_help_page_url = Rails.application.routes.url_helpers.help_page_url('user/project/use_project_as_go_package')
        not_found_message = "Go package not found or access denied. If you are trying to access a private project, ensure your ~/.netrc file has credentials so the go toolchain can authenticate. See #{go_help_page_url} for details."

        [404, { 'Content-Type' => 'text/plain' }, [not_found_message]]
      end

      # handle_go_get_request returns a go get HTML document response if the project exists and the user has read access
      # otherwise it returns a 404 response with a message for the go toolchain to display.
      def handle_go_get_request(request)
        path_info = request.env["PATH_INFO"].delete_prefix('/')
        project = project_for_path(path_info)

        # return the same way when a repo is not found or the user has no access
        # so that we don't reveal the existence of a project the user doesn't have access to.
        return not_found_response unless project&.repository_exists?
        return not_found_response unless can_read_project?(request, project)

        html = create_go_get_html(project)
        response = Rack::Response.new(html, 200, { 'Content-Type' => 'text/html' })
        response.finish
      end

      def go_get_request?(request)
        request["go-get"].to_i == 1 && request.env["PATH_INFO"].present?
      end

      # create_go_get_html creates a HTML document for go get with the expected meta tags.
      def create_go_get_html(project)
        # See https://go.dev/ref/mod for documentation on the `go-import` meta tag.
        root_path = Gitlab::Utils.append_path(Gitlab.config.gitlab.host, project.full_path)
        repo_url = Gitlab::CurrentSettings.enabled_git_access_protocol == 'ssh' ? ssh_url(project.full_path) : project.http_url_to_repo
        go_import_meta_tag = tag.meta(name: 'go-import', content: "#{root_path} git #{repo_url}")

        # See https://github.com/golang/gddo/wiki/Source-Code-Links for documentation on the `go-source` meta tag.
        if project.default_branch
          source_home = Gitlab::Utils.append_path(Gitlab.config.gitlab.url, project.full_path)
          source_directory = "#{source_home}/-/tree/#{project.default_branch}{/dir}"
          source_file = "#{source_home}/-/blob/#{project.default_branch}{/dir}/{file}#L{line}"
          go_source_meta_tag = tag.meta(name: 'go-source', content: "#{root_path} #{source_home} #{source_directory} #{source_file}")
          head_tag = content_tag :head, go_import_meta_tag + go_source_meta_tag
        else
          head_tag = content_tag :head, go_import_meta_tag
        end

        body_tag = content_tag :body, "go get #{root_path}"

        content_tag :html, head_tag + body_tag
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

        Project.where_full_path_in(project_paths).first
      end

      # can_read_project? checks if the request's credentials have read access to the project
      def can_read_project?(request, project)
        return true if project.public?

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

      # ------ Deprecated code ---------
      # Remove when `not_found_response_for_go_get` FF is enabled
      def render_go_doc(request)
        return unless go_get_request?(request)

        path, branch = project_path(request)
        return unless path

        body, code = go_response(path, branch)
        return unless body

        response = Rack::Response.new(body, code, { 'Content-Type' => 'text/html' })
        response.finish
      end

      def go_response(path, branch)
        config = Gitlab.config
        body_tag = content_tag :body, "go get #{config.gitlab.host}/#{path}"

        unless branch
          html_tag = content_tag :html, body_tag
          return html_tag, 404
        end

        project_url = Gitlab::Utils.append_path(config.gitlab.url, path)
        import_prefix = strip_url(project_url.to_s)

        repository_url = if Gitlab::CurrentSettings.enabled_git_access_protocol == 'ssh'
                           ssh_url(path)
                         else
                           "#{project_url}.git"
                         end

        meta_import_tag = tag.meta(name: 'go-import', content: "#{import_prefix} git #{repository_url}")
        meta_source_tag = tag.meta(name: 'go-source', content: "#{import_prefix} #{project_url} #{project_url}/-/tree/#{branch}{/dir} #{project_url}/-/blob/#{branch}{/dir}/{file}#L{line}")
        head_tag = content_tag :head, meta_import_tag + meta_source_tag
        html_tag = content_tag :html, head_tag + body_tag
        [html_tag, 200]
      end

      def strip_url(url)
        url.gsub(%r{\Ahttps?://}, '')
      end

      def project_path(request)
        path_info = request.env["PATH_INFO"]
        path_info.sub!(%r{^/}, '')

        project_path_match = "#{path_info}/".match(PROJECT_PATH_REGEX)
        return unless project_path_match

        path = project_path_match[1]

        # Go subpackages may be in the form of `namespace/project/path1/path2/../pathN`.
        # In a traditional project with a single namespace, this would denote repo
        # `namespace/project` with subpath `path1/path2/../pathN`, but with nested
        # groups, this could also be `namespace/project/path1` with subpath
        # `path2/../pathN`, for example.

        # We find all potential project paths out of the path segments
        path_segments = path.split('/')
        simple_project_path = path_segments.first(2).join('/')

        project_paths = []
        begin
          project_paths << path_segments.join('/')
          path_segments.pop
        end while path_segments.length >= 2

        # We see if a project exists with any of these potential paths
        project = project_for_paths(project_paths, request)

        if project
          # If a project is found and the user has access, we return the full project path
          [project.full_path, project.default_branch]
        else
          # If not, we return the first two components as if it were a simple `namespace/project` path,
          # so that we don't reveal the existence of a nested project the user doesn't have access to.
          # This means that for an unauthenticated request to `group/subgroup/project/subpackage`
          # for a private `group/subgroup/project` with subpackage path `subpackage`, GitLab will respond
          # as if the user is looking for project `group/subgroup`, with subpackage path `project/subpackage`.
          # Since `go get` doesn't authenticate by default, this means that
          # `go get gitlab.com/group/subgroup/project/subpackage` will not work for private projects.
          # `go get gitlab.com/group/subgroup/project.git/subpackage` will work, since Go is smart enough
          # to figure that out. `import 'gitlab.com/...'` behaves the same as `go get`.
          [simple_project_path, 'master']
        end
      end

      def project_for_paths(paths, request)
        project = Project.where_full_path_in(paths).first

        return unless authentication_result(request, project).can_perform_action_on_project?(:read_project, project)

        project
      end

      def authentication_result(request, project)
        empty_result = Gitlab::Auth::Result::EMPTY
        return empty_result unless has_basic_credentials?(request)

        login, password = user_name_and_password(request)
        auth_result = Gitlab::Auth.find_for_git_client(login, password, project: project, request: request)
        return empty_result unless auth_result.success?

        return empty_result unless auth_result.can?(:access_git)

        return empty_result unless auth_result.authentication_abilities_include?(:read_project)

        auth_result
      end
    end
  end
end

# A dumb middleware that returns a Go HTML document if the go-get=1 query string
# is used irrespective if the namespace/project exists
module Gitlab
  module Middleware
    class Go
      include ActionView::Helpers::TagHelper

      PROJECT_PATH_REGEX = %r{\A(#{Gitlab::PathRegex.full_namespace_route_regex}/#{Gitlab::PathRegex.project_route_regex})/}.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        render_go_doc(request) || @app.call(env)
      end

      private

      def render_go_doc(request)
        return unless go_request?(request)

        path = project_path(request)
        return unless path

        body = go_body(path)
        return unless body

        response = Rack::Response.new(body, 200, { 'Content-Type' => 'text/html' })
        response.finish
      end

      def go_request?(request)
        request["go-get"].to_i == 1 && request.env["PATH_INFO"].present?
      end

      def go_body(path)
        config = Gitlab.config
        project_url = URI.join(config.gitlab.url, path)
        import_prefix = strip_url(project_url.to_s)

        repository_url = if Gitlab::CurrentSettings.enabled_git_access_protocol == 'ssh'
                           shell = config.gitlab_shell
                           port = ":#{shell.ssh_port}" unless shell.ssh_port == 22
                           "ssh://#{shell.ssh_user}@#{shell.ssh_host}#{port}/#{path}.git"
                         else
                           "#{project_url}.git"
                         end

        meta_tag = tag :meta, name: 'go-import', content: "#{import_prefix} git #{repository_url}"
        head_tag = content_tag :head, meta_tag
        content_tag :html, head_tag
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

        # If the path is at most 2 segments long, it is a simple `namespace/project` path and we're done
        return simple_project_path if path_segments.length <= 2

        project_paths = []
        begin
          project_paths << path_segments.join('/')
          path_segments.pop
        end while path_segments.length >= 2

        # We see if a project exists with any of these potential paths
        project = project_for_paths(project_paths, request)

        if project
          # If a project is found and the user has access, we return the full project path
          project.full_path
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
          simple_project_path
        end
      end

      def project_for_paths(paths, request)
        project = Project.where_full_path_in(paths).first
        return unless Ability.allowed?(current_user(request), :read_project, project)

        project
      end

      def current_user(request)
        authenticator = Gitlab::Auth::RequestAuthenticator.new(request)
        user = authenticator.find_user_from_access_token || authenticator.find_user_from_warden

        return unless user&.can?(:access_api)

        # Right now, the `api` scope is the only one that should be able to determine private project existence.
        return unless authenticator.valid_access_token?(scopes: [:api])

        user
      end
    end
  end
end

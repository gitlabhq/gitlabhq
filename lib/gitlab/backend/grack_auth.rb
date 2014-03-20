require_relative 'shell_env'

module Grack
  class Auth < Rack::Auth::Basic

    attr_accessor :user, :project, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      # Need this patch due to the rails mount

      # Need this if under RELATIVE_URL_ROOT
      unless Gitlab.config.gitlab.relative_url_root.empty?
        # If website is mounted using relative_url_root need to remove it first
        @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root,'')
      else
        @env['PATH_INFO'] = @request.path
      end

      @env['SCRIPT_NAME'] = ""

      auth!
    end

    private

    def auth!
      return render_not_found unless project

      if @auth.provided?
        return bad_request unless @auth.basic?

        # Authentication with username and password
        login, password = @auth.credentials

        # Allow authentication for GitLab CI service
        # if valid token passed
        if login == "gitlab-ci-token" && project.gitlab_ci?
          token = project.gitlab_ci_service.token

          if token.present? && token == password && service_name == 'git-upload-pack'
            return @app.call(env)
          end
        end

        @user = authenticate_user(login, password)

        if @user
          Gitlab::ShellEnv.set_env(@user)
          @env['REMOTE_USER'] = @auth.username
        else
          return unauthorized
        end

      else
        return unauthorized unless project.public?
      end

      if authorized_git_request?
        @app.call(env)
      else
        unauthorized
      end
    end

    def authorized_git_request?
      authorize_request(service_name)
    end

    def authenticate_user(login, password)
      auth = Gitlab::Auth.new
      auth.find(login, password)
    end

    def authorize_request(service)
      case service
      when *Gitlab::GitAccess::DOWNLOAD_COMMANDS
        # Serve only upload request.
        # Authorization on push will be serverd by update hook in repository
        Gitlab::GitAccess.new.download_allowed?(user, project)
      when *Gitlab::GitAccess::PUSH_COMMANDS
        true
      else
        false
      end
    end

    def service_name
      if @request.get?
        @request.params['service']
      elsif @request.post?
        File.basename(@request.path)
      else
        nil
      end
    end

    def project
      @project ||= project_by_path(@request.path_info)
    end

    def project_by_path(path)
      if m = /^([\w\.\/-]+)\.git/.match(path).to_a
        path_with_namespace = m.last
        path_with_namespace.gsub!(/\.wiki$/, '')

        Project.find_with_namespace(path_with_namespace)
      end
    end

    def render_not_found
      [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
    end
  end
end

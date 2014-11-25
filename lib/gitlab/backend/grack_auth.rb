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

      if project
        auth!
      else
        render_not_found
      end
    end

    private

    def auth!
      if @auth.provided?
        return bad_request unless @auth.basic?

        # Authentication with username and password
        login, password = @auth.credentials

        # Allow authentication for GitLab CI service
        # if valid token passed
        if gitlab_ci_request?(login, password)
          return @app.call(env)
        end

        @user = authenticate_user(login, password)

        if @user
          Gitlab::ShellEnv.set_env(@user)
          @env['REMOTE_USER'] = @auth.username
        end
      end

      if authorized_request?
        @app.call(env)
      else
        unauthorized
      end
    end

    def gitlab_ci_request?(login, password)
      if login == "gitlab-ci-token" && project.gitlab_ci?
        token = project.gitlab_ci_service.token

        if token.present? && token == password && git_cmd == 'git-upload-pack'
          return true
        end
      end

      false
    end

    def authenticate_user(login, password)
      auth = Gitlab::Auth.new
      auth.find(login, password)
    end

    def authorized_request?
      case git_cmd
      when *Gitlab::GitAccess::DOWNLOAD_COMMANDS
        if user
          Gitlab::GitAccess.new.download_access_check(user, project).allowed?
        elsif project.public?
          # Allow clone/fetch for public projects
          true
        else
          false
        end
      when *Gitlab::GitAccess::PUSH_COMMANDS
        if user
          # Skip user authorization on upload request.
          # It will be done by the pre-receive hook in the repository.
          true
        else
          false
        end
      else
        false
      end
    end

    def git_cmd
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

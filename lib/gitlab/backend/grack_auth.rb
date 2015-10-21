require_relative 'shell_env'

module Grack
  class AuthSpawner
    def self.call(env)
      # Avoid issues with instance variables in Grack::Auth persisting across
      # requests by creating a new instance for each request.
      Auth.new({}).call(env)
    end
  end

  class Auth < Rack::Auth::Basic

    attr_accessor :user, :project, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      @ci = false

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

      if project && authorized_request?
        # Tell gitlab-git-http-server the request is OK, and what the GL_ID is
        render_grack_auth_ok
      elsif @user.nil? && !@ci
        unauthorized
      else
        render_not_found
      end
    end

    private

    def auth!
      return unless @auth.provided?

      return bad_request unless @auth.basic?

      # Authentication with username and password
      login, password = @auth.credentials

      # Allow authentication for GitLab CI service
      # if valid token passed
      if ci_request?(login, password)
        @ci = true
        return
      end

      @user = authenticate_user(login, password)

      if @user
        Gitlab::ShellEnv.set_env(@user)
        @env['REMOTE_USER'] = @auth.username
      end
    end

    def ci_request?(login, password)
      matched_login = /(?<s>^[a-zA-Z]*-ci)-token$/.match(login)

      if project && matched_login.present? && git_cmd == 'git-upload-pack'
        underscored_service = matched_login['s'].underscore 

        if Service.available_services_names.include?(underscored_service)
          service_method = "#{underscored_service}_service"
          service = project.send(service_method)

          return service && service.activated? && service.valid_token?(password)
        end
      end

      false
    end

    def oauth_access_token_check(login, password)
      if login == "oauth2" && git_cmd == 'git-upload-pack' && password.present?
        token = Doorkeeper::AccessToken.by_token(password)
        token && token.accessible? && User.find_by(id: token.resource_owner_id)
      end
    end

    def authenticate_user(login, password)
      user = Gitlab::Auth.new.find(login, password)

      unless user
        user = oauth_access_token_check(login, password)
      end

      # If the user authenticated successfully, we reset the auth failure count
      # from Rack::Attack for that IP. A client may attempt to authenticate
      # with a username and blank password first, and only after it receives
      # a 401 error does it present a password. Resetting the count prevents
      # false positives from occurring.
      #
      # Otherwise, we let Rack::Attack know there was a failed authentication
      # attempt from this IP. This information is stored in the Rails cache
      # (Redis) and will be used by the Rack::Attack middleware to decide
      # whether to block requests from this IP.
      config = Gitlab.config.rack_attack.git_basic_auth

      if config.enabled
        if user
          # A successful login will reset the auth failure count from this IP
          Rack::Attack::Allow2Ban.reset(@request.ip, config)
        else
          banned = Rack::Attack::Allow2Ban.filter(@request.ip, config) do
            # Unless the IP is whitelisted, return true so that Allow2Ban
            # increments the counter (stored in Rails.cache) for the IP
            if config.ip_whitelist.include?(@request.ip)
              false
            else
              true
            end
          end

          if banned
            Rails.logger.info "IP #{@request.ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
          end
        end
      end

      user
    end

    def authorized_request?
      return true if @ci

      case git_cmd
      when *Gitlab::GitAccess::DOWNLOAD_COMMANDS
        if !Gitlab.config.gitlab_shell.upload_pack
          false
        elsif user
          Gitlab::GitAccess.new(user, project).download_access_check.allowed?
        elsif project.public?
          # Allow clone/fetch for public projects
          true
        else
          false
        end
      when *Gitlab::GitAccess::PUSH_COMMANDS
        if !Gitlab.config.gitlab_shell.receive_pack
          false
        elsif user
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
      return @project if defined?(@project)

      @project = project_by_path(@request.path_info)
    end

    def project_by_path(path)
      if m = /^([\w\.\/-]+)\.git/.match(path).to_a
        path_with_namespace = m.last
        path_with_namespace.gsub!(/\.wiki$/, '')

        path_with_namespace[0] = '' if path_with_namespace.start_with?('/')
        Project.find_with_namespace(path_with_namespace)
      end
    end

    def render_grack_auth_ok
      [
        200,
        { "Content-Type" => "application/json" },
        [JSON.dump({
          'GL_ID' => Gitlab::ShellEnv.gl_id(@user),
          'RepoPath' => project.repository.path_to_repo,
        })]
      ]
    end

    def render_not_found
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    end
  end
end

module Grack
  class AuthSpawner
    def self.call(env)
      # Avoid issues with instance variables in Grack::Auth persisting across
      # requests by creating a new instance for each request.
      Auth.new({}).call_with_kerberos_support(env)
    end
  end

  class Auth < Rack::Auth::Basic
    attr_accessor :user, :project, :env

    def call_with_kerberos_support(env)
      # Make sure the final leg of Kerberos authentication is applied as per RFC4559
      apply_negotiate_final_leg(call(env))
    end

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      @ci = false

      # Need this patch due to the rails mount
      # Need this if under RELATIVE_URL_ROOT
      unless Gitlab.config.gitlab.relative_url_root.empty?
        # If website is mounted using relative_url_root need to remove it first
        @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root, '')
      else
        @env['PATH_INFO'] = @request.path
      end

      @env['SCRIPT_NAME'] = ""

      auth!

      lfs_response = Gitlab::Lfs::Router.new(project, @user, @ci, @request).try_call
      return lfs_response unless lfs_response.nil?

      if @user.nil? && !@ci
        unauthorized
      else
        render_not_found
      end
    end

    private

    def allow_basic_auth?
      return true unless Gitlab.config.kerberos.enabled &&
                         Gitlab.config.kerberos.use_dedicated_port &&
                         @env['SERVER_PORT'] == Gitlab.config.kerberos.port.to_s
    end

    def allow_kerberos_auth?
      return false unless Gitlab.config.kerberos.enabled
      return true unless Gitlab.config.kerberos.use_dedicated_port
      # When using a dedicated port, allow Kerberos auth only if port matches the configured one
      @env['SERVER_PORT'] == Gitlab.config.kerberos.port.to_s
    end

    def spnego_challenge
      return "Negotiate" unless @auth.spnego_response_token
      "Negotiate #{::Base64.strict_encode64(@auth.spnego_response_token)}"
    end

    def challenge
      challenges = []
      challenges << super if allow_basic_auth?
      challenges << spnego_challenge if allow_kerberos_auth?
      # Use \n separator to generate multiple WWW-Authenticate headers in case of multiple challenges
      challenges.join("\n")
    end

    def apply_negotiate_final_leg(response)
      return response unless allow_kerberos_auth? && @auth.spnego_response_token
      # As per RFC4559, we may have a final WWW-Authenticate header to send in
      # the response even if it's not a 401 status
      status, headers, body = response
      headers['WWW-Authenticate'] = spnego_challenge

      [status, headers, body]
    end

    def valid_auth_method?
      (allow_basic_auth? && @auth.basic?) || (allow_kerberos_auth? && @auth.negotiate?)
    end

    def auth!
      return unless @auth.provided?

      return bad_request unless valid_auth_method?

      if @auth.negotiate?
        # Authentication with Kerberos token
        krb_principal = @auth.spnego_credentials!
        return unless krb_principal

        # Set @user if authentication succeeded
        identity = ::Identity.find_by(provider: :kerberos, extern_uid: krb_principal)
        @user = identity.user if identity
      else
        # Authentication with username and password
        login, password = @auth.credentials

        # Allow authentication for GitLab CI service
        # if valid token passed
        if ci_request?(login, password)
          @ci = true
          return
        end

        @user = authenticate_user(login, password)
      end
    end

    def ci_request?(login, password)
      matched_login = /(?<s>^[a-zA-Z]*-ci)-token$/.match(login)

      if project && matched_login.present?
        underscored_service = matched_login['s'].underscore

        if underscored_service == 'gitlab_ci'
          return project && project.valid_build_token?(password)
        elsif Service.available_services_names.include?(underscored_service)
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
      user = Gitlab::Auth.find_with_user_password(login, password)

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

    def render_not_found
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    end

    class Request < Rack::Auth::Basic::Request
      attr_reader :spnego_response_token

      def negotiate?
        parts.first && scheme == "negotiate"
      end

      def spnego_token
        ::Base64.strict_decode64(params)
      end

      def spnego_credentials!
        require 'gssapi'
        gss = GSSAPI::Simple.new(nil, nil, Gitlab.config.kerberos.keytab)
        # the GSSAPI::Simple constructor transforms a nil service name into a default value, so
        # pass service name to acquire_credentials explicitly to support the special meaning of nil
        gss_service_name =
          if Gitlab.config.kerberos.service_principal_name.present?
            gss.import_name(Gitlab.config.kerberos.service_principal_name)
          else
            nil # accept any valid service principal name from keytab
          end
        gss.acquire_credentials(gss_service_name) # grab credentials from keytab

        # Decode token
        gss_result = gss.accept_context(spnego_token)

        # gss_result will be 'true' if nothing has to be returned to the client
        @spnego_response_token = gss_result if gss_result && gss_result != true

        # Return user principal name if authentication succeeded
        gss.display_name
      rescue GSSAPI::GssApiError => ex
        Rails.logger.error "#{self.class.name}: failed to process Negotiate/Kerberos authentication: #{ex.message}"
        false
      end
    end
  end
end

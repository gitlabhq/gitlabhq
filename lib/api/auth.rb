module API
  # Projects builds API
  class Auth < Grape::API
    namespace 'auth' do
      get 'token' do
        required_attributes! [:service]
        keys = attributes_for_keys [:offline_token, :scope, :service]

        case keys[:service]
        when 'docker'
          docker_token_auth(keys[:scope], keys[:offline_token])
        else
          not_found!
        end
      end
    end

    helpers do
      def docker_token_auth(scope, offline_token)
        auth!

        if offline_token
          forbidden! unless @user
        elsif scope
          @type, @path, actions = scope.split(':', 3)
          bad_request!("invalid type: #{@type}") unless @type == 'repository'

          @actions = actions.split(',')
          bad_request!('missing actions') if @actions.empty?

          @project = Project.find_with_namespace(@path)
          not_found!('Project') unless @project

          authorize_actions!(@actions)
        end

        { token: encode(docker_payload) }
      end

      def auth!
        auth = BasicRequest.new(request.env)
        return unless auth.provided?

        return bad_request unless auth.basic?

        # Authentication with username and password
        login, password = auth.credentials

        if ci_request?(login, password)
          @ci = true
          return
        end

        @user = authenticate_user(login, password)

        if @user
          request.env['REMOTE_USER'] = @user.username
        end
      end

      def ci_request?(login, password)
        matched_login = /(?<s>^[a-zA-Z]*-ci)-token$/.match(login)

        if @project && matched_login.present?
          underscored_service = matched_login['s'].underscore

          if underscored_service == 'gitlab_ci'
            return @project.valid_build_token?(password)
          end
        end

        false
      end

      def authenticate_user(login, password)
        user = Gitlab::Auth.new.find(login, password)

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

      def docker_payload
        {
          access: [
            type: @type,
            name: @path,
            actions: @actions
          ],
          iss: Gitlab.config.registry.issuer,
          exp: Time.now.to_i + 3600
        }
      end

      def private_key
        @private_key ||= OpenSSL::PKey::RSA.new File.read Gitlab.config.registry.key
      end

      def encode(payload)
        JWT.encode(payload, private_key, 'RS256')
      end

      def authorize_actions!(actions)
        actions.each do |action|
          forbidden! unless can_access?(action)
        end
      end

      def can_access?(action)
        case action
        when 'pull'
          @ci || can?(@user, :download_code, @project)
        when 'push'
          @ci || can?(@user, :push_code, @project)
        else
          false
        end
      end

      class BasicRequest < Rack::Auth::AbstractRequest
        def basic?
          "basic" == scheme
        end

        def credentials
          @credentials ||= params.unpack("m*").first.split(/:/, 2)
        end

        def username
          credentials.first
        end
      end
    end
  end
end

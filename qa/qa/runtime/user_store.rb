# frozen_string_literal: true

module QA
  module Runtime
    # Helper class to create and store globally accessible test users
    #
    class UserStore
      InvalidTokenError = Class.new(StandardError)
      ExpiredAdminPasswordError = Class.new(StandardError)

      # @return [String] default admin api token pre-seeded on ephemeral test environments
      DEFAULT_ADMIN_API_TOKEN = "ypCa3Dzb23o5nvsixwPA" # gitleaks:allow
      # @return [String] default username for admin user
      DEFAULT_ADMIN_USERNAME = "root"
      # @return [String] default password for admin user
      DEFAULT_ADMIN_PASSWORD = "5iveL!fe"

      class << self
        # Default api client depending on environment setup
        #
        # @return [QA::Runtime::API::Client]
        def default_api_client
          user_api_client || admin_api_client
        end

        # Global admin client
        #
        # @return [QA::Runtime::API::Client]
        def admin_api_client
          return @admin_api_client if defined?(@admin_api_client)
          return @admin_api_client = nil if Env.no_admin_environment?

          info("Creating admin api client for api fabrications")
          @admin_api_client = create_api_client(
            token: Env.admin_personal_access_token,
            user_proc: -> { admin_user },
            default_token: DEFAULT_ADMIN_API_TOKEN,
            check_admin: true)

          info("Global admin api client set up successfully")
          @admin_api_client
        end
        alias_method :initialize_admin_api_client, :admin_api_client

        # Global test user api client
        # This api client is used as a primary one for resource fabrication that do not require admin privileges
        #
        # @return [QA::Runtime::API::Client]
        def user_api_client
          return @user_api_client if defined?(@user_api_client)

          @user_api_client = if create_unique_test_user?
                               test_user.api_client
                             else
                               info("Creating api client for test user")
                               create_api_client(token: Env.personal_access_token, user_proc: -> { test_user })
                             end
        rescue StandardError => e
          # consider test user api client optional and set to nil if not setup
          warn("Failed to create test user api client: #{e.message}")
          @user_api_client = nil
        end
        alias_method :initialize_user_api_client, :user_api_client

        # Global admin user
        #
        # @return [QA::Resource::User]
        def admin_user
          return @admin_user if defined?(@admin_user)
          return @admin_user = nil if Env.no_admin_environment?

          @admin_user = create_user(username: Env.admin_username, password: Env.admin_password,
            default_username: DEFAULT_ADMIN_USERNAME, default_password: DEFAULT_ADMIN_PASSWORD,
            api_client: @admin_api_client)
        end
        alias_method :initialize_admin_user, :admin_user

        # Global test user
        # This user is used as a primary one for test execution
        #
        # @return [QA::Resource::User]
        def test_user
          return @test_user if defined?(@test_user)

          info("Creating test user")

          if ldap_user_configured?
            return @test_user = Resource::User.init do |user|
              user.username = Env.ldap_username
              user.password = Env.ldap_password
              user.ldap_user = true
            end
          elsif create_unique_test_user?
            return @test_user = create_new_user
          end

          if Env.user_username.blank? || Env.user_password.blank?
            raise "Missing user_username and user_password variable values"
          end

          @test_user = create_user(username: Env.user_username, password: Env.user_password,
            api_client: @user_api_client)
        rescue StandardError => e
          # consider test user optional and set to nil if not setup
          # once unique user creation on non live environments is implemented, this should be removed
          warn("Failed to create test user: #{e.message}")
          @test_user = nil
        end
        alias_method :initialize_test_user, :test_user

        # Reset stored test user
        #
        # @return [void]
        def reset_test_user!
          remove_instance_variable(:@test_user) if instance_variable_defined?(:@test_user)
          remove_instance_variable(:@user_api_client) if instance_variable_defined?(:@user_api_client)
        end

        private

        delegate :debug, :info, :warn, :error, to: Logger

        # Create unique test user when fetching test user instead of using predefined one
        #
        # @return [Boolean]
        def create_unique_test_user?
          !Env.running_on_live_env? && admin_api_client
        end

        # Create api client with provided token with fallback to UI creation of token
        #
        # @param [String] token
        # @param [Proc] user_proc
        # @param [String] default_token
        # @return [QA::Runtime::API::Client]
        def create_api_client(token:, user_proc:, default_token: nil, check_admin: false)
          if token
            info("Global api token variable is set, using it for api client setup")
            API::Client
              .new(personal_access_token: token)
              .tap { |client| validate_api_client!(client, check_admin: check_admin) }
          elsif token_valid?(default_token, check_admin: check_admin)
            info("Api token variable is not set, using default - '#{default_token}'")
            API::Client.new(personal_access_token: default_token)
          else
            info("Creating personal access token via UI")
            # pass user through proc so it's lazily initialized only when fabricating token via UI
            user = user_proc.call
            raise "Failed to create personal access token, no user provided!" if user.nil?

            create_api_token_via_ui!(user)
            user.api_client
          end
        end

        # Initialize new user
        #
        # @param [String] username
        # @param [String] password
        # @param [String] default_username
        # @param [String] default_password
        # @param [QA::Runtime::API::Client] api_client
        # @return [QA::Resource::User]
        def create_user(username:, password:, default_username: nil, default_password: nil, api_client: nil)
          return if (username.nil? && default_username.nil?) || (password.nil? && default_password.nil?)

          user = Resource::User.init do |user|
            user.username = if username
                              username
                            else
                              debug("Username variable not set, using default - '#{default_username}'")
                              default_username
                            end

            user.password = if password
                              password
                            else
                              debug("Password variable not set, using default - '#{default_password}'")
                              default_password
                            end
          end

          if api_client && client_belongs_to_user?(api_client, user)
            user.api_client = api_client
            user.reload!
          elsif api_client
            warn(<<~WARN)
              Configured global api client does not belong to configured global user
              Please check values for user authentication related variables
            WARN
          end

          user
        end

        # Create new user with personal access token
        #
        # @return [QA::Resource::User]
        def create_new_user
          Resource::User.fabricate_via_api! do |user|
            user.with_personal_access_token = true
            user.api_client = admin_api_client
          end
        end

        # Check if provided token is valid?
        #
        # @param [String] token
        # @param [Boolean] check_admin
        # @return [Boolean]
        def token_valid?(token, check_admin:)
          return unless token

          debug("Validating if api token is valid")
          validate_api_client!(API::Client.new(personal_access_token: token), check_admin: check_admin)
          debug("Api token is valid")
          true
        rescue InvalidTokenError
          debug("Api token is not valid, skipping...")
          false
        end

        # Create api token via UI for provided user
        # Update user api_client to use fabricated token
        #
        # @param [QA::Resource::User] user
        # @return [String]
        def create_api_token_via_ui!(user)
          pat = Resource::PersonalAccessToken.fabricate_via_browser_ui! do |resource|
            resource.username = user.username
            resource.password = user.password
          end

          user.api_client = Runtime::API::Client.new(personal_access_token: pat.token)
          user.reload!
          user.add_personal_access_token(pat)

          pat.token
        end

        # Validate if client belongs to an admin user
        #
        # @param [QA::Runtime::API::Client] client
        # @return [void]
        def validate_api_client!(client, check_admin: true)
          debug("Validating api client")
          resp = fetch_user_details(client)

          if resp.code == 403 && resp.body.include?("Your password expired")
            raise ExpiredAdminPasswordError, "Password for client's user has expired and must be reset"
          elsif !status_ok?(resp)
            raise InvalidTokenError, "API client validation failed! Code: #{resp.code}, Err: '#{resp.body}'"
          end

          if check_admin
            is_admin = Support::API.parse_body(resp)[:is_admin]
            raise InvalidTokenError, "Admin token does not belong to admin user" unless is_admin
          end

          debug("API client is valid")
        end

        # Check if token belongs to specific user
        #
        # @param [QA::Runtime::API::Client] client
        # @param [QA::Resource::User] user
        # @return [Boolean]
        def client_belongs_to_user?(client, user)
          resp = fetch_user_details(client)
          unless status_ok?(resp)
            raise InvalidTokenError, "API client validation failed! Code: #{resp.code}, Err: '#{resp.body}'"
          end

          Support::API.parse_body(resp)[:username] == user.username
        end

        # Fetch user details of given api client
        #
        # @param [QA::Runtime::API::Client] client
        # @return [RestClient::Response]
        def fetch_user_details(client)
          Support::API.get(API::Request.new(client, "/user").url)
        end

        # Validate 200 HTTP status code of response
        #
        # @param [RestClient::Response] resp
        # @return [Boolean]
        def status_ok?(resp)
          resp.code == Support::API::HTTP_STATUS_OK
        end

        # Check if environment has ldap user set
        #
        # @return [Boolean]
        def ldap_user_configured?
          Runtime::Env.ldap_username.present? && Runtime::Env.ldap_password.present?
        end
      end
    end
  end
end

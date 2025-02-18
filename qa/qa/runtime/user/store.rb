# frozen_string_literal: true

module QA
  module Runtime
    module User
      MissingUserCredentialError = Class.new(StandardError)
      MissingLdapCredentialsError = Class.new(StandardError)
      InvalidTokenError = Class.new(StandardError)
      InvalidCredentialsError = Class.new(StandardError)
      ExpiredPasswordError = Class.new(StandardError)

      # User store class responsible for creating and storing test users
      #
      class Store
        extend Data

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
            return @admin_api_client = nil if Env.no_admin_environment? || Env.personal_access_tokens_disabled?

            info("Creating admin api client for api fabrications")
            @admin_api_client = create_api_client(
              token: admin_api_token,
              default_token: Data::DEFAULT_ADMIN_API_TOKEN,
              user_proc: -> { admin_user },
              check_admin: true)

            info("Global admin api client set up successfully")
            @admin_api_client
          rescue InvalidCredentialsError => e
            unless admin_username == Data::DEFAULT_ADMIN_USERNAME && admin_password == Data::DEFAULT_ADMIN_PASSWORD
              # Only raise error when explicitly configured credentials are invalid
              raise e
            end

            # Because default credentials for admin api token fabrications will be always used,
            # allow for test process to continue without admin client when default credentials are invalid
            warn("Valid administrator user credentials missing!")
            warn("All actions that require administrator api client will be skipped or fail!")
            @admin_api_client = nil
          end
          alias_method :initialize_admin_api_client, :admin_api_client

          # Global test user api client
          # This api client is used as a primary one for resource fabrication that do not require admin privileges
          #
          # @return [QA::Runtime::API::Client]
          def user_api_client
            return @user_api_client if defined?(@user_api_client)
            return @user_api_client = nil if Env.personal_access_tokens_disabled?

            @user_api_client = if create_unique_test_user?
                                 test_user.api_client
                               else
                                 info("Creating api client for global test user")
                                 create_api_client(token: test_user_api_token, user_proc: -> { test_user })
                               end
          end
          alias_method :initialize_user_api_client, :user_api_client

          # Global admin user
          #
          # @return [QA::Resource::User]
          def admin_user
            return @admin_user if defined?(@admin_user)
            return @admin_user = nil if Env.no_admin_environment?

            info("Initializing admin user using predefined credentials")
            @admin_user = init_user(
              username: admin_username,
              password: admin_password,
              api_client: @admin_api_client,
              admin: true
            )
          end
          alias_method :initialize_admin_user, :admin_user

          # Global test user used as a primary user for test execution
          #
          # @return [QA::Resource::User]
          def test_user
            return @test_user if defined?(@test_user)

            if ldap_user_configured?
              info("LDAP credentials configured, using LDAP user for test as main test user")
              return @test_user = ldap_user
            elsif create_unique_test_user?
              return @test_user = create_new_user
            end

            if test_user_username.blank? || test_user_password.blank?
              raise <<~ERR
                Missing global test user credentials,
                please set '#{Data::TEST_USER_USERNAME_VARIABLE_NAME}' and '#{Data::TEST_USER_PASSWORD_VARIABLE_NAME}' environment variables
              ERR
            end

            info("Initializing test user using predefined credentials")
            @test_user = init_user(
              username: test_user_username,
              password: test_user_password,
              api_client: @user_api_client
            )
          end
          alias_method :initialize_test_user, :test_user

          # Instance of user with LDAP username and password
          #
          # @return [QA::Resource::User]
          def ldap_user
            raise MissingLdapCredentialsError, 'LDAP credentials not configured' unless ldap_user_configured?

            Resource::User.init do |user|
              user.username = ldap_username
              user.password = ldap_password
              user.ldap_user = true
            end
          end

          # Additional test user
          #
          # @return [QA::Resource::User]
          def additional_test_user
            return create_new_user if admin_api_client

            init_user(
              username: extra_test_user_credential(Data::ADDITIONAL_TEST_USERNAME_VARIABLE_NAME),
              password: extra_test_user_credential(Data::ADDITIONAL_TEST_PASSWORD_VARIABLE_NAME)
            ).reload!
          end

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
            return false unless Env.create_unique_test_users?

            !Env.running_on_live_env? && !Env.personal_access_tokens_disabled? && admin_api_client
          end

          # Create api client with provided token with fallback to UI creation of token
          #
          # @param [String] token
          # @param [Proc] user_proc
          # @param [String] default_token
          # @return [QA::Runtime::API::Client]
          def create_api_client(token:, user_proc:, default_token: nil, check_admin: false)
            if token
              API::Client.new(personal_access_token: token).tap do |client|
                validate_api_client!(client, check_admin: check_admin)
              end
            elsif default_token.present? && token_valid?(default_token, check_admin: check_admin)
              API::Client.new(personal_access_token: default_token).tap do |client|
                validate_api_client!(client, check_admin: check_admin)
              end
            else
              info("Creating personal access token via UI")
              # pass user through proc so it's lazily initialized only when fabricating token via UI
              user = user_proc.call
              raise "Failed to create personal access token, no user provided!" if user.nil?

              create_api_token_via_ui!(user)
              user.api_client
            end
          end

          # Initialize new user with predefined username and password
          #
          # @param [String] username
          # @param [String] password
          # @param [QA::Runtime::API::Client] api_client
          # @param [Boolean] admin
          # @return [QA::Resource::User]
          def init_user(username:, password:, api_client: nil, admin: false)
            return if username.nil? || password.nil?

            user = Resource::User.init do |user|
              user.username = username
              user.password = password
              user.is_admin = admin
            end

            if api_client && client_belongs_to_user?(api_client, user)
              user.api_client = api_client
              user.reload!
            elsif api_client
              warn <<~WARN
                Configured api client does not belong to the user
                Please check values for user authentication related variables
              WARN
            end

            user
          end

          # Create new user with personal access token
          #
          # @return [QA::Resource::User]
          def create_new_user
            info("Creating test user")
            Resource::User.fabricate! do |user|
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
          rescue InvalidTokenError => e
            debug("Api token is not valid, error: #{e}. Skipping...")
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
              raise ExpiredPasswordError, "Password for client's user has expired and must be reset"
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
            ldap_username.present? && ldap_password.present?
          end

          # Additional test user credential
          #
          # @param var_name [String]
          # @return [String]
          def extra_test_user_credential(var_name)
            ENV[var_name].presence || raise(MissingUserCredentialError, "Missing '#{var_name}' environment variable")
          end
        end
      end
    end
  end
end

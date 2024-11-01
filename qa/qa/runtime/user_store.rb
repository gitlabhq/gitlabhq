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
        # Global admin client
        #
        # @return [QA::Runtime::API::Client]
        def admin_api_client
          return @admin_api_client if @admin_api_client

          info("Creating admin api client for api fabrications")

          if Env.admin_personal_access_token
            info("Admin api token variable is set, using it for default admin api fabrications")
            @admin_api_client = API::Client
              .new(personal_access_token: Env.admin_personal_access_token)
              .tap { |client| validate_admin_client!(client) }
          elsif default_admin_token_valid?
            info("Admin api token variable is not set, using default - '#{DEFAULT_ADMIN_API_TOKEN}'")
            @admin_api_client = API::Client.new(personal_access_token: DEFAULT_ADMIN_API_TOKEN)
          else
            @admin_api_client = create_admin_api_client(admin_user)
          end

          info("Admin token set up successfully")
          @admin_api_client
        end
        alias_method :initialize_admin_api_client, :admin_api_client

        # Global admin user
        #
        # @return [QA::Resource::User]
        def admin_user
          return @admin_user if @admin_user

          @admin_user = Resource::User.init do |user|
            user.username = if Env.admin_username
                              Env.admin_username
                            else
                              debug("Admin username variable not set, using default - '#{DEFAULT_ADMIN_USERNAME}'")
                              DEFAULT_ADMIN_USERNAME
                            end

            user.password = if Env.admin_password
                              Env.admin_password
                            else
                              debug("Admin password variable not set, using default - '#{DEFAULT_ADMIN_PASSWORD}'")
                              DEFAULT_ADMIN_PASSWORD
                            end
          end

          if @admin_api_client && client_belongs_to_user?(@admin_api_client, @admin_user)
            @admin_user.api_client = @admin_api_client
            @admin_user.reload!
          elsif @admin_api_client
            warn(<<~WARN)
              Configured global admin token does not belong to configured admin user
              Please check values for GITLAB_QA_ADMIN_ACCESS_TOKEN, GITLAB_ADMIN_USERNAME and GITLAB_ADMIN_PASSWORD variables
            WARN
          end

          @admin_user
        end
        alias_method :initialize_admin_user, :admin_user

        private

        delegate :debug, :info, :warn, :error, to: Logger

        # Check if default admin token is present in environment and valid
        #
        # @return [Boolean]
        def default_admin_token_valid?
          debug("Validating presence of default admin api token in environment")
          validate_admin_client!(API::Client.new(personal_access_token: DEFAULT_ADMIN_API_TOKEN))
          debug("Default admin token is present in environment and is valid")
          true
        rescue InvalidTokenError
          debug("Default admin token is not valid or present in environment, skipping...")
          false
        end

        # Create admin access client and validate it
        #
        # @param [QA::Resource::User] user
        # @return [QA::Runtime::API::Client]
        def create_admin_api_client(user)
          info("Creating admin token via ui")
          admin_token = Flow::Login.while_signed_in(as: user) do
            Resource::PersonalAccessToken.fabricate_via_browser_ui! { |pat| pat.user = user }.token
          end

          API::Client.new(:gitlab, personal_access_token: admin_token).tap do |client|
            validate_admin_client!(client)
            user.api_client = client
            user.reload!
          end
        end

        # Validate if client belongs to an admin user
        #
        # @param [QA::Runtime::API::Client] client
        # @return [void]
        def validate_admin_client!(client)
          debug("Validating admin access token")
          resp = fetch_user_details(client)

          if resp.code == 403 && resp.body.include?("Your password expired")
            raise ExpiredAdminPasswordError, "Admin password has expired and must be reset"
          elsif !status_ok?(resp)
            raise InvalidTokenError, "Admin token validation failed! Code: #{resp.code}, Err: '#{resp.body}'"
          end

          is_admin = Support::API.parse_body(resp)[:is_admin]
          raise InvalidTokenError, "Admin token does not belong to admin user" unless is_admin

          debug("Admin token is valid")
        end

        # Check if token belongs to specific user
        #
        # @param [QA::Runtime::API::Client] client
        # @param [QA::Resource::User] user
        # @return [Boolean]
        def client_belongs_to_user?(client, user)
          resp = fetch_user_details(client)
          unless status_ok?(resp)
            raise InvalidTokenError, "Token validation failed! Code: #{resp.code}, Err: '#{resp.body}'"
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
      end
    end
  end
end

# frozen_string_literal: true

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use.
  # Currently supported options are :active_record, :mongoid2, :mongoid3, :mongo_mapper
  orm :active_record

  # Restore to pre-5.1 generator due to breaking change.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/244371
  default_generator_method :hex

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    # Put your resource owner authentication logic here.
    if current_user
      current_user
    else
      # Ensure user is redirected to redirect_uri after login
      session[:user_return_to] = request.fullpath
      redirect_to(new_user_session_url)
      nil
    end
  end

  resource_owner_from_credentials do |_routes|
    user = User.find_by_login(params[:username])
    next unless user

    next if user.password_automatically_set? && !user.password_based_omniauth_user?
    next if user.two_factor_enabled? || Gitlab::Auth::TwoFactorAuthVerifier.new(user).two_factor_authentication_enforced?

    Gitlab::Auth.find_with_user_password(params[:username], params[:password], increment_failed_attempts: true)
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  # admin_authenticator do
  #   # Put your admin authentication logic here.
  #   # Example implementation:
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
  # end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  # reuse_access_token

  # Issue access tokens with refresh token (disabled by default)
  use_refresh_token

  # Forbids creating/updating applications with arbitrary scopes that are
  # not in configuration, i.e. `default_scopes` or `optional_scopes`.
  # (disabled by default)
  enforce_configured_scopes

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  force_ssl_in_redirect_uri false

  # Specify what redirect URI's you want to block during Application creation.
  # Any redirect URI is whitelisted by default.
  #
  # You can use this option in order to forbid URI's with 'javascript' scheme
  # for example.
  forbid_redirect_uri { |uri| %w[data vbscript javascript].include?(uri.scheme.to_s.downcase) }

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter confirmation: true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  enable_application_owner confirmation: false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  default_scopes(*Gitlab::Auth::DEFAULT_SCOPES)
  optional_scopes(*Gitlab::Auth.optional_scopes)

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  access_token_methods :from_access_token_param, :from_bearer_authorization, :from_bearer_param

  hash_token_secrets using: '::Gitlab::DoorkeeperSecretStoring::Token::Pbkdf2Sha512', fallback: :plain

  hash_application_secrets using: '::Gitlab::DoorkeeperSecretStoring::Secret::Pbkdf2Sha512', fallback: :plain

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  grant_flows %w[authorization_code password client_credentials device_code]

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with trusted a application.
  skip_authorization do |resource_owner, client|
    client.application.trusted?
  end

  # WWW-Authenticate Realm (default "Doorkeeper").
  # realm "Doorkeeper"

  base_controller '::Gitlab::BaseDoorkeeperController'

  # Allow Resource Owner Password Credentials Grant without client credentials,
  # this was disabled by default in Doorkeeper 5.5.
  #
  skip_client_authentication_for_password_grant -> { Gitlab::CurrentSettings.ropc_without_client_credentials }

  # 2 hours in seconds
  # This is also the database default value
  #
  # WARNING: If this is less than `300` some unexpected behavior may occur.
  # For example, the Web IDE has a baked in expiration buffer of 5 minutes, so
  # the Web IDE would treat all tokens as expired if this value is `300` or less.
  access_token_expires_in 7200

  # Use a custom class for generating the application secret.
  # https://doorkeeper.gitbook.io/guides/configuration/other-configurations#custom-application-secret-generator
  application_secret_generator 'Gitlab::DoorkeeperSecretStoring::Token::UniqueApplicationToken'

  custom_access_token_attributes [:organization_id]

  enable_dynamic_scopes
  # Following doorkeeper monkey patches are to identify the organization on best effort basis

  Doorkeeper::OAuth::PasswordAccessTokenRequest.class_eval do
    private

    def before_successful_response
      organization = Gitlab::Current::Organization.new(user: resource_owner).organization

      find_or_create_access_token(client, resource_owner, scopes, { organization_id: organization.id }, server)
      super
    end

    def validate_client
      if Doorkeeper.config.skip_client_authentication_for_password_grant.call
        client.present? || (!parameters[:client_id] && credentials.blank?)
      else
        client.present?
      end
    end
  end

  Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest.class_eval do
    # @return [Hash]
    def device_grant_attributes
      {
        application_id: client.id,
        expires_in: configuration.device_code_expires_in,
        scopes: scopes.to_s,
        user_code: generate_user_code,
        organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID
      }
    end
  end

  Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceCodeRequest.class_eval do
    def generate_access_token
      find_or_create_access_token(
        device_grant.application,
        device_grant.resource_owner_id,
        device_grant.scopes,
        { organization_id: device_grant.organization_id },
        server
      )
    end
  end

  Doorkeeper::OpenidConnect::OAuth::Authorization::Code.class_eval do
    private

    def create_openid_request(access_grant)
      ::Doorkeeper::OpenidConnect::Request.create!(
        access_grant: access_grant,
        nonce: pre_auth.nonce,
        organization_id: access_grant.organization_id
      )
    end
  end
end

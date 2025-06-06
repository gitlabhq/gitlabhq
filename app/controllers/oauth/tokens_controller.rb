# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  include EnforcesTwoFactorAuthentication
  include RequestPayloadLogger
  include Gitlab::InternalEventsTracking

  alias_method :auth_user, :current_user

  def create
    if authorize_response.status == :ok
      track_internal_event(
        'oauth_authorize_with_gitlab',
        user: authorize_response.token.resource_owner,
        additional_properties: {
          label: server.client.present?.to_s,
          property: params[:grant_type] # rubocop:disable Rails/StrongParams -- This pattern is followed in the gem
        }
      )
    end

    super
  end

  private

  def validate_presence_of_client
    return if Doorkeeper.config.skip_client_authentication_for_password_grant.call

    # @see 2.1.  Revocation Request
    #
    #  The client constructs the request by including the following
    #  parameters using the "application/x-www-form-urlencoded" format in
    #  the HTTP request entity-body:
    #     token   REQUIRED.
    #     token_type_hint  OPTIONAL.
    #
    #  The client also includes its authentication credentials as described
    #  in Section 2.3. of [RFC6749].
    #
    #  The authorization server first validates the client credentials (in
    #  case of a confidential client) and then verifies whether the token
    #  was issued to the client making the revocation request.
    return if server.client

    # If this validation [client credentials / token ownership] fails, the request is
    # refused and the  client is informed of the error by the authorization server as
    # described below.
    #
    # @see 2.2.1.  Error Response
    #
    # The error presentation conforms to the definition in Section 5.2 of [RFC6749].
    render json: revocation_error_response, status: :forbidden
  end
end

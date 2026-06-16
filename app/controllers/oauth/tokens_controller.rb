# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  include EnforcesTwoFactorAuthentication
  include RequestPayloadLogger
  include Gitlab::InternalEventsTracking

  # RFC 7636 Section 4.1 requires PKCE code verifiers to be at least 43 characters.
  # Track requests that use shorter verifiers to measure how many clients are non-compliant
  # before enforcing the minimum.
  PKCE_MIN_CODE_VERIFIER_LENGTH = 43

  before_action :validate_pkce_for_dynamic_applications, only: [:create]
  before_action :track_short_pkce_verifier, only: [:create]

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

  # In Rails 8 alias_method at class-body level fails when the aliased method
  # is not yet in the ancestor chain at load time. Define explicitly instead.
  def auth_user
    current_user
  end

  def append_info_to_payload(payload)
    super

    if @authorize_response.respond_to?(:token) && @authorize_response.token.is_a?(Doorkeeper::AccessToken)
      payload[:metadata] ||= {}
      payload[:metadata][:oauth_access_token_id] = @authorize_response.token.id
      payload[:metadata][:oauth_access_token_application_id] = @authorize_response.token.application_id
      payload[:metadata][:oauth_access_token_scopes] = @authorize_response.token.scopes_string
    end

    # rubocop:disable Rails/StrongParams -- following existing param access pattern
    if params[:grant_type] == 'refresh_token' && params[:refresh_token].present?
      payload[:metadata] ||= {}
      payload[:metadata][:refresh_token_hash] = Digest::SHA256.hexdigest(params[:refresh_token])[0..9]
    end
    # rubocop:enable Rails/StrongParams

    payload
  end

  def validate_pkce_for_dynamic_applications
    return unless server.client&.application&.dynamic?
    # PKCE validation only applies to authorization_code grants per RFC 7636 Section 4.5.
    return unless params[:grant_type] == 'authorization_code' # rubocop:disable Rails/StrongParams -- Only accessing a single named param
    return unless params[:code_verifier].blank? # rubocop:disable Rails/StrongParams -- Only accessing a single named param

    render json: {
      error: 'invalid_request',
      error_description: 'PKCE code_verifier is required for dynamic OAuth applications'
    }, status: :bad_request
  end

  def track_short_pkce_verifier
    return unless params[:grant_type] == 'authorization_code' # rubocop:disable Rails/StrongParams -- Only accessing a single named param

    verifier = params[:code_verifier] # rubocop:disable Rails/StrongParams -- Only accessing a single named param
    return if verifier.blank? || verifier.length >= PKCE_MIN_CODE_VERIFIER_LENGTH

    track_internal_event(
      'oauth_authorize_with_short_pkce_verifier',
      user: current_user,
      additional_properties: {
        label: server.client&.uid.to_s
      }
    )
  end
end

# frozen_string_literal: true

module Webauthn
  class AuthenticateService < BaseService
    include Authn::WebauthnErrors
    include SafeFormatHelper

    def initialize(user, device_response, challenge)
      @user = user
      @device_response = device_response
      @challenge = challenge
    end

    def execute
      parsed_device_response = Gitlab::Json.parse(@device_response)

      webauthn_credential = WebAuthn::Credential.from_get(parsed_device_response)
      encoded_raw_id = Base64.strict_encode64(webauthn_credential.raw_id)
      stored_webauthn_credential = stored_passkey_or_second_factor_webauthn_credential(encoded_raw_id)

      encoder = WebAuthn.configuration.encoder

      verify_webauthn(stored_webauthn_credential, webauthn_credential, @challenge, encoder)

      stored_webauthn_credential.update!(
        counter: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      ServiceResponse.success(
        message: _('WebAuthn device successfully authenticated.')
      )

    rescue JSON::ParserError
      ServiceResponse.error(
        message: _('Your webauthn device did not send a valid JSON response.')
      )
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(
        message: webauthn_credential_not_found_error
      )
    rescue WebAuthn::Error => err
      ServiceResponse.error(
        message: webauthn_human_readable_errors(err.class.name)
      )
    end

    private

    def webauthn_credential_not_found_error
      docs_link = ActionController::Base.helpers.link_to(
        _('recover'),
        Rails.application.routes.url_helpers.help_page_url(
          'user/profile/account/two_factor_authentication_troubleshooting.md',
          anchor: 'recovery-options-and-2fa-reset'
        ),
        target: '_blank',
        rel: 'noopener noreferrer'
      )

      safe_format(
        _('Authentication via WebAuthn device failed. Use another 2FA method or %{two_factor_recovery_hyperlink} your account.'),
        two_factor_recovery_hyperlink: docs_link
      )
    end

    def verify_webauthn(stored_webauthn_credential, webauthn_credential, challenge, encoder)
      stored_webauthn_credential &&
        validate_webauthn_credential(webauthn_credential) &&
        verify_webauthn_credential(webauthn_credential, stored_webauthn_credential, challenge, encoder)
    end

    def stored_passkey_or_second_factor_webauthn_credential(encoded_raw_id)
      if Feature.enabled?(:passkeys, @user)
        credential = @user.passkeys.find_by_credential_xid(encoded_raw_id) ||
          @user.second_factor_webauthn_registrations.find_by_credential_xid(encoded_raw_id)

        raise(ActiveRecord::RecordNotFound) unless credential

        credential
      else
        @user.second_factor_webauthn_registrations.find_by_credential_xid!(encoded_raw_id)
      end
    end

    ##
    # Validates that webauthn_credential is syntactically valid
    #
    # duplicated from WebAuthn::PublicKeyCredential#verify
    # which can't be used here as we need to call WebAuthn::AuthenticatorAssertionResponse#verify instead
    # (which is done in #verify_webauthn_credential)
    def validate_webauthn_credential(webauthn_credential)
      webauthn_credential.type == WebAuthn::TYPE_PUBLIC_KEY &&
        webauthn_credential.raw_id && webauthn_credential.id &&
        webauthn_credential.raw_id == WebAuthn.standard_encoder.decode(webauthn_credential.id)
    end

    ##
    # Verifies that webauthn_credential matches stored_credential with the given challenge
    #
    def verify_webauthn_credential(webauthn_credential, stored_credential, challenge, encoder)
      # We need to adjust the relaying party id (RP id) we verify against if the registration in question
      # is a migrated U2F registration. This is because the appid of U2F and the rp id of WebAuthn differ.
      rp_id = webauthn_credential&.client_extension_outputs&.dig('appid') ? WebAuthn.configuration.origin : URI(WebAuthn.configuration.origin).host
      webauthn_credential.response.verify(
        encoder.decode(challenge),
        public_key: encoder.decode(stored_credential.public_key),
        sign_count: stored_credential.counter,
        rp_id: rp_id
      )
    end
  end
end

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
      parsed_device_response = Gitlab::Json.safe_parse(@device_response)

      webauthn_credential = WebAuthn::Credential.from_get(parsed_device_response)
      encoded_raw_id = Base64.strict_encode64(webauthn_credential.raw_id)
      stored_webauthn_credential = stored_passkey_or_second_factor_webauthn_credential(encoded_raw_id)

      webauthn_credential.verify(
        @challenge,
        public_key: stored_webauthn_credential.public_key,
        sign_count: stored_webauthn_credential.counter
      )

      raise WebAuthn::Error if stored_webauthn_credential.passkey? && !@user.allow_passkey_authentication?

      stored_webauthn_credential.update!(
        counter: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      ServiceResponse.success(
        message: _('WebAuthn device successfully authenticated.')
      )

    rescue JSON::ParserError
      ServiceResponse.error(
        message: _('Your WebAuthn device did not send a valid JSON response.')
      )
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(
        message: webauthn_credential_not_found_error
      )
    rescue WebAuthn::Error => err
      ServiceResponse.error(
        message: webauthn_human_readable_errors(err.class.name, passkey: stored_webauthn_credential.passkey?)
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

    def stored_passkey_or_second_factor_webauthn_credential(encoded_raw_id)
      @user.webauthn_registrations.find_by_credential_xid!(encoded_raw_id)
    end
  end
end

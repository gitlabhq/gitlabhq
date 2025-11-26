# frozen_string_literal: true

module Webauthn
  class RegisterService < BaseService
    def initialize(user, params, challenge)
      @user = user
      @params = params
      @challenge = challenge
    end

    def execute
      registration = WebauthnRegistration.new

      begin
        webauthn_credential = WebAuthn::Credential.from_create(Gitlab::Json.safe_parse(@params[:device_response]))
        webauthn_credential.verify(@challenge)

        registration.update(
          credential_xid: Base64.strict_encode64(webauthn_credential.raw_id),
          public_key: webauthn_credential.public_key,
          counter: webauthn_credential.sign_count,
          name: @params[:name],
          user: @user,
          passkey_eligible: passkey?(webauthn_credential),
          last_used_at: Time.current
        )
      rescue JSON::ParserError
        registration.errors.add(:base, _('Your WebAuthn device did not send a valid JSON response.'))
      rescue WebAuthn::Error => e
        registration.errors.add(:base, e.message)
      end

      registration
    end

    private

    def passkey?(passkey_credential)
      !!passkey_credential&.client_extension_outputs&.dig("credProps", "rk")
    end
  end
end

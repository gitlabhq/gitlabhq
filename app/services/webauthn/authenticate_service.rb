# frozen_string_literal: true

module Webauthn
  class AuthenticateService < BaseService
    def initialize(user, device_response, challenge)
      @user = user
      @device_response = device_response
      @challenge = challenge
    end

    def execute
      parsed_device_response = Gitlab::Json.parse(@device_response)

      webauthn_credential = WebAuthn::Credential.from_get(parsed_device_response)
      encoded_raw_id = Base64.strict_encode64(webauthn_credential.raw_id)
      stored_webauthn_credential = @user.webauthn_registrations.find_by_credential_xid(encoded_raw_id)

      encoder = WebAuthn.configuration.encoder

      if stored_webauthn_credential &&
          validate_webauthn_credential(webauthn_credential) &&
          verify_webauthn_credential(webauthn_credential, stored_webauthn_credential, @challenge, encoder)

        stored_webauthn_credential.update!(counter: webauthn_credential.sign_count)
        return true
      end

      false
    rescue JSON::ParserError, WebAuthn::SignCountVerificationError, WebAuthn::Error
      false
    end

    private

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
      rp_id = webauthn_credential.client_extension_outputs['appid'] ? WebAuthn.configuration.origin : URI(WebAuthn.configuration.origin).host
      webauthn_credential.response.verify(
        encoder.decode(challenge),
        public_key: encoder.decode(stored_credential.public_key),
        sign_count: stored_credential.counter,
        rp_id: rp_id
      )
    end
  end
end

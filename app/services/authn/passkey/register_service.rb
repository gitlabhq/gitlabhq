# frozen_string_literal: true

module Authn
  module Passkey
    class RegisterService < BaseService
      include WebauthnErrors

      def initialize(user, params, challenge)
        @user = user
        @params = params
        @challenge = challenge
      end

      def execute
        registration = WebauthnRegistration.new

        begin
          passkey_credential = WebAuthn::Credential.from_create(Gitlab::Json.parse(@params[:device_response]))
          passkey_credential.verify(@challenge)

          @passkey_credential = passkey_credential

          registration.update!(
            credential_xid: Base64.strict_encode64(@passkey_credential.raw_id),
            public_key: @passkey_credential.public_key,
            counter: @passkey_credential.sign_count,
            name: @params[:name],
            user: @user,
            authentication_mode: :passwordless,
            passkey_eligible: true,
            last_used_at: Time.current
          )

          ServiceResponse.success(
            message: _('Passkey added successfully! Next time you sign in, select the sign-in with passkey option.'),
            payload: registration
          )
        rescue JSON::ParserError
          ServiceResponse.error(
            message: _('Your passkey did not send a valid JSON response.')
          )
        rescue ActiveRecord::RecordInvalid => err
          ServiceResponse.error(
            message: err.message
          )
        rescue WebAuthn::Error => err
          ServiceResponse.error(
            message: webauthn_human_readable_errors(err.class.name, passkey: true)
          )
        end
      end
    end
  end
end

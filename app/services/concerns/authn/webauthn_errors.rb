# frozen_string_literal: true

#
# Stores & maps error messages for WebAuthn (2FA device & passkey) errors.
#
module Authn
  module WebauthnErrors
    extend ActiveSupport::Concern

    def webauthn_error_messages
      {
        'WebAuthn::AttestationStatementVerificationError' => {
          webauthn: _('Could not verify device authenticity. Try using a different device.'),
          passkey: _('Could not verify passkey authenticity. Try using a different passkey.')
        },
        'WebAuthn::AttestedCredentialVerificationError' => {
          webauthn: _('Invalid credential data received. Try registering the device again.'),
          passkey: _('Invalid passkey data received. Try creating a new passkey.')
        },
        'WebAuthn::AuthenticatorDataVerificationError' => {
          webauthn: _('Failed to add authentication method. Try again.'),
          passkey: _('Failed to add passkey. Try again.')
        },
        'WebAuthn::ChallengeVerificationError' => {
          webauthn: _('Failed to verify WebAuthn challenge. Try again.'),
          passkey: _('Failed to verify WebAuthn challenge. Try again.')
        },
        'WebAuthn::OriginVerificationError' => {
          webauthn: _('Unable to use this authentication method. Try a different authentication method.'),
          passkey: _('Unable to use this authentication method. Try a different authentication method.')
        },
        'WebAuthn::RpIdVerificationError' => {
          webauthn: _('Failed to authenticate due to a configuration issue. Try again later or contact support.'),
          passkey: _('Failed to authenticate due to a configuration issue. Try again later or contact support.')
        },
        'WebAuthn::SignatureVerificationError' => {
          webauthn: _('Failed to verify cryptographic signature. Try authenticating again.'),
          passkey: _('Failed to verify cryptographic signature. Try authenticating again.')
        },
        'WebAuthn::SignCountVerificationError' => {
          webauthn: _('Authenticator may have been cloned. Contact your administrator.'),
          passkey: _('Passkey may have been cloned. Contact your administrator.')
        },
        'WebAuthn::TokenBindingVerificationError' => {
          webauthn: _('Failed to verify connection security. Try adding the authentication method again.'),
          passkey: _('Failed to verify connection security. Try adding the authentication method again.')
        },
        'WebAuthn::TypeVerificationError' => {
          webauthn: _('This authentication method is not supported. Use a different authentication method.'),
          passkey: _('This authentication method is not supported. Use a different authentication method.')
        },
        'WebAuthn::UserPresenceVerificationError' => {
          webauthn: _('Failed to authenticate. Verify your identity with your device.'),
          passkey: _('Failed to authenticate. Verify your identity with your device.')
        },
        'WebAuthn::UserVerifiedVerificationError' => {
          webauthn: _('Failed to authenticate. Verify your identity with your device.'),
          passkey: _('Failed to authenticate. Verify your identity with your device.')
        }
      }.freeze
    end

    def webauthn_generic_error_messages
      {
        webauthn: _('Failed to add authentication method. Try again.'),
        passkey: _('Failed to connect to your device. Try again.')
      }.freeze
    end

    # Returns a human readable error message, given a webauthn/passkey error class_name.
    #
    # Accepts a `WebAuthn::Error` class.name  and an optional keyword argument `passkey: true`
    # if called from a Passkey bounded context.
    #
    def webauthn_human_readable_errors(error_message_class_name, passkey: nil)
      return unless error_message_class_name && error_message_class_name.is_a?(String)

      if passkey
        webauthn_error_messages.dig(error_message_class_name, :passkey) ||
          webauthn_generic_error_messages[:passkey]
      else
        webauthn_error_messages.dig(error_message_class_name, :webauthn) ||
          webauthn_generic_error_messages[:webauthn]
      end
    end
  end
end

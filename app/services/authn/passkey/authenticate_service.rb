# frozen_string_literal: true

# Handles passwordless authentication with passkeys, specifically on the sign_in page.
#
module Authn
  module Passkey
    class AuthenticateService < BaseService
      include WebauthnErrors
      include SafeFormatHelper

      def initialize(device_response, challenge)
        @device_response = device_response
        @challenge = challenge
      end

      def execute
        parsed_device_response = Gitlab::Json.parse(@device_response)

        passkey_credential = WebAuthn::Credential.from_get(parsed_device_response)
        encoded_raw_id = Base64.strict_encode64(passkey_credential.raw_id)
        @stored_passkey_credential = find_matching_credential_xid(encoded_raw_id)

        encoder = WebAuthn.configuration.encoder

        verify_passkey(@stored_passkey_credential, passkey_credential, @challenge, encoder)

        @stored_passkey_credential.update!(
          counter: passkey_credential.sign_count,
          last_used_at: Time.current
        )

        ServiceResponse.success(
          message: _('Passkey successfully authenticated.'),
          payload: find_matching_user_with_passkey(@stored_passkey_credential)
        )

      rescue JSON::ParserError
        ServiceResponse.error(
          message: _('Your passkey did not send a valid JSON response.')
        )
      rescue ActiveRecord::RecordNotFound
        ServiceResponse.error(
          message: record_not_found_error_message
        )
      rescue WebAuthn::Error => err
        ServiceResponse.error(
          message: webauthn_human_readable_errors(err.class.name, passkey: true)
        )
      end

      private

      def record_not_found_error_message
        docs_link = ActionController::Base.helpers.link_to('',
          Rails.application.routes.url_helpers.help_page_url(
            'auth/passkeys.md',
            anchor: 'add-a-passkey'
          ),
          target: '_blank',
          rel: 'noopener noreferrer'
        )

        safe_format(
          _(
            'Failed to authenticate passkey. Sign in with your username and password to add a passkey for your ' \
              'account. Learn more about %{link_start}setting up passkeys%{link_end}.'
          ), tag_pair(docs_link, :link_start, :link_end)
        )
      end

      def verify_passkey(stored_passkey_credential, passkey_credential, challenge, encoder)
        stored_passkey_credential &&
          validate_passkey_credential(passkey_credential) &&
          verify_passkey_credential(passkey_credential, stored_passkey_credential, challenge, encoder)
      end

      def find_matching_credential_xid(possible_user_passkey_credential_xid)
        WebauthnRegistration.passkey.find_by_credential_xid!(possible_user_passkey_credential_xid)
      end

      def find_matching_user_with_passkey(existing_credential_xid)
        User.find(existing_credential_xid.user_id)
      end

      ##
      # Validates that webauthn_credential is syntactically valid
      #
      # duplicated from WebAuthn::PublicKeyCredential#verify
      # which can't be used here as we need to call WebAuthn::AuthenticatorAssertionResponse#verify instead
      # (which is done in #verify_webauthn_credential)
      def validate_passkey_credential(passkey_credential)
        passkey_credential.type == WebAuthn::TYPE_PUBLIC_KEY &&
          passkey_credential.raw_id && passkey_credential.id &&
          passkey_credential.raw_id == WebAuthn.standard_encoder.decode(passkey_credential.id)
      end

      #
      # Verifies that authenticator response's webauthn_credential matches the stored_credential,
      # with the given challenge
      #
      def verify_passkey_credential(passkey_credential, stored_credential, challenge, encoder)
        passkey_credential.response.verify(
          encoder.decode(challenge),
          public_key: encoder.decode(stored_credential.public_key),
          sign_count: stored_credential.counter,
          rp_id: URI(WebAuthn.configuration.origin).host
        )
      end
    end
  end
end

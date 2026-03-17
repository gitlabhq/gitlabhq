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
        parsed_device_response = Gitlab::Json.safe_parse(@device_response)

        passkey_credential = WebAuthn::Credential.from_get(parsed_device_response)
        encoded_raw_id = Base64.strict_encode64(passkey_credential.raw_id)
        stored_passkey_credential = find_matching_credential_xid(encoded_raw_id)

        passkey_credential.verify(
          @challenge,
          public_key: stored_passkey_credential.public_key,
          sign_count: stored_passkey_credential.counter
        )

        @user = find_matching_user_with_passkey(stored_passkey_credential)

        raise WebAuthn::Error unless @user.allow_passkey_authentication?

        stored_passkey_credential.update!(
          counter: passkey_credential.sign_count,
          last_used_at: Time.current
        )

        ServiceResponse.success(
          message: _('Passkey successfully authenticated.'),
          payload: @user
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

      def find_matching_credential_xid(possible_user_passkey_credential_xid)
        WebauthnRegistration.passkey.find_by_credential_xid!(possible_user_passkey_credential_xid)
      end

      def find_matching_user_with_passkey(existing_credential_xid)
        User.find(existing_credential_xid.user_id)
      end
    end
  end
end

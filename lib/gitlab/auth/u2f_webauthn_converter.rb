# frozen_string_literal: true

require 'webauthn/u2f_migrator'

module Gitlab
  module Auth
    class U2fWebauthnConverter
      def initialize(u2f_registration)
        @u2f_registration = u2f_registration
      end

      def convert
        now = Time.current

        converted_credential = WebAuthn::U2fMigrator.new(
          app_id: Gitlab.config.gitlab.url,
          certificate: u2f_registration.certificate,
          key_handle: u2f_registration.key_handle,
          public_key: u2f_registration.public_key,
          counter: u2f_registration.counter
        ).credential

        {
          credential_xid: Base64.strict_encode64(converted_credential.id),
          public_key: Base64.strict_encode64(converted_credential.public_key),
          counter: u2f_registration.counter || 0,
          name: u2f_registration.name || '',
          user_id: u2f_registration.user_id,
          u2f_registration_id: u2f_registration.id,
          created_at: now,
          updated_at: now
        }
      end

      private

      attr_reader :u2f_registration
    end
  end
end

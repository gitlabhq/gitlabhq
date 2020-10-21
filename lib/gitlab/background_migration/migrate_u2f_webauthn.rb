# frozen_string_literal: true
# rubocop:disable Style/Documentation
require "webauthn/u2f_migrator"

module Gitlab
  module BackgroundMigration
    class MigrateU2fWebauthn
      class U2fRegistration < ActiveRecord::Base
        self.table_name = 'u2f_registrations'
      end

      class WebauthnRegistration < ActiveRecord::Base
        self.table_name = 'webauthn_registrations'
      end

      def perform(start_id, end_id)
        old_registrations = U2fRegistration.where(id: start_id..end_id)
        old_registrations.each_slice(100) do |slice|
          now = Time.now
          values = slice.map do |u2f_registration|
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

          WebauthnRegistration.insert_all(values, unique_by: :credential_xid, returning: false)
        end
      end
    end
  end
end

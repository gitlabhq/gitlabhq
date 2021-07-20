# frozen_string_literal: true
# rubocop:disable Style/Documentation

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
          values = slice.map do |u2f_registration|
            converter = Gitlab::Auth::U2fWebauthnConverter.new(u2f_registration)
            converter.convert
          end

          WebauthnRegistration.insert_all(values, unique_by: :credential_xid, returning: false)
        end
      end
    end
  end
end

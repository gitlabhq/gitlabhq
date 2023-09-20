# frozen_string_literal: true

module Gitlab
  module Auth
    module Devise
      module Strategies
        # This strategy combines the following strategies from
        # devise_two_factor gem:
        # - TwoFactorAuthenticatable: https://github.com/devise-two-factor/devise-two-factor/blob/v4.0.2/lib/devise_two_factor/strategies/two_factor_authenticatable.rb
        # - TwoFactorBackupable: https://github.com/devise-two-factor/devise-two-factor/blob/v4.0.2/lib/devise_two_factor/strategies/two_factor_backupable.rb
        # to avoid double incrementing failed login attempts counter by each
        # strategy in case an incorrect password is provided.
        class CombinedTwoFactorAuthenticatable < ::Devise::Strategies::DatabaseAuthenticatable
          def authenticate!
            resource = mapping.to.find_for_database_authentication(authentication_hash)

            # We check the OTP / backup code, then defer to DatabaseAuthenticatable
            is_valid = validate(resource) do
              validate_otp(resource) || resource.invalidate_otp_backup_code!(params[scope]['otp_attempt'])
            end

            if is_valid
              # Devise fails to authenticate invalidated resources, but if we've
              # gotten here, the object changed (Since we deleted a recovery code)
              resource.save!

              super
            end

            fail(::Devise.paranoid ? :invalid : :not_found_in_database) unless resource # rubocop: disable Style/SignalException

            # We want to cascade to the next strategy if this one fails,
            # but database authenticatable automatically halts on a bad password
            @halted = false if @result == :failure
          end

          def validate_otp(resource)
            return true unless resource.otp_required_for_login

            return if params[scope]['otp_attempt'].nil?

            resource.validate_and_consume_otp!(params[scope]['otp_attempt'])
          end
        end
      end
    end
  end
end

Warden::Strategies.add(
  :combined_two_factor_authenticatable,
  Gitlab::Auth::Devise::Strategies::CombinedTwoFactorAuthenticatable)

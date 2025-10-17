# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      # Validates expiration of step-up authentication sessions based on ID token exp claims
      #
      # This validator handles time-based expiration for step-up authentication sessions
      # using OIDC ID token exp claims.
      class StepUpAuthExpirationValidator
        Result = Struct.new(:valid?, :expired?, :message, :current_time, :exp_timestamp,
          keyword_init: true)

        class << self
          # Main validation method that returns a Result struct
          #
          # @param session_data [Hash] the session data containing expiration information
          # @return [Result] validation result object
          def validate(session_data)
            unless session_data.is_a?(Hash)
              return Result.new(
                valid?: false,
                expired?: false,
                message: 'No session data provided'
              )
            end

            exp_timestamp = session_data['exp_timestamp']
            unless exp_timestamp.present?
              return Result.new(
                valid?: false,
                expired?: false,
                message: 'No expiration timestamp in session'
              )
            end

            current_time = Time.current.to_i
            expired = current_time > exp_timestamp

            Result.new(
              valid?: true,
              expired?: expired,
              message: expired ? 'Session expired' : 'Session valid',
              current_time: current_time,
              exp_timestamp: exp_timestamp
            )
          end
        end
      end
    end
  end
end

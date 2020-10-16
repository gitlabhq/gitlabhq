# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        class Devise < Base
          def validate(otp_code)
            user.validate_and_consume_otp!(otp_code) ? success : error('invalid OTP code')
          end
        end
      end
    end
  end
end

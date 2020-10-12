# frozen_string_literal: true
require 'rotp'

module QA
  module Support
    class OTP
      def initialize(secret)
        @rotp = ROTP::TOTP.new(secret)
      end

      def fresh_otp
        otps = []

        # Fetches a fresh OTP and returns it only after rotp provides the same OTP twice
        # An OTP is valid for 30 seconds so 70 attempts with 0.5 interval would ensure we complete 1 cycle

        QA::Runtime::Logger.debug("Fetching a fresh OTP...")
        Support::Retrier.retry_until(max_attempts: 70, sleep_interval: 0.5, log: false) do
          otps << @rotp.now
          otps.size >= 3 && otps[-1] == otps[-2] && otps[-1] != otps[-3]
        end

        QA::Runtime::Logger.debug("Fetched OTP: #{otps.last}")
        otps.last
      end
    end
  end
end

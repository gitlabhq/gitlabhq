# frozen_string_literal: true

require 'benchmark'

module QA
  module Vendor
    module OnePassword
      class CLI
        include Singleton

        def initialize
          @email = QA::Runtime::Env.one_p_email
          @password = QA::Runtime::Env.one_p_password
          @secret = QA::Runtime::Env.one_p_secret
          @github_uuid = QA::Runtime::Env.one_p_github_uuid
          @address = 'gitlab.1password.com'
        end

        def new_otp(old_otp = "")
          # Fetches a new OTP that is not equal to the old OTP
          new_otp = ""
          time = Benchmark.realtime do
            # An otp is valid for 30 seconds so 64 attempts with 0.5 interval are enough to ensure a new OTP is obtained
            Support::Retrier.retry_until(max_attempts: 64, sleep_interval: 0.5) do
              new_otp = current_otp
              new_otp != old_otp
            end
          end

          QA::Runtime::Logger.info("Fetched new OTP in: #{time} seconds")

          new_otp
        end

        def current_otp
          result = nil

          time = Benchmark.realtime do
            result = `op item get #{@github_uuid} --otp --session #{session_token}`.chop
          end

          QA::Runtime::Logger.info("Fetched current OTP in: #{time} seconds")

          result
        end

        private

        # OP session tokens are valid for 30 minutes. We are caching the session token here and this is fine currently
        # as we just have one test that is not expected to go over 30 minutes.
        # But note that if we add more tests that use this class, we might need to add a mechanism to invalidate
        # the cache after 30 minutes or if the session_token is rejected by op CLI.
        def session_token
          @session_token ||= `echo '#{@password}' | op account add --address #{@address} --email #{@email} --secret-key #{@secret} --signin --raw`
        end
      end
    end
  end
end

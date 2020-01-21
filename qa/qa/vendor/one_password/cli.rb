# frozen_string_literal: true

require 'benchmark'

module QA
  module Vendor
    module OnePassword
      class CLI
        include Singleton

        def initialize
          @email = QA::Runtime::Env.gitlab_qa_1p_email
          @password = QA::Runtime::Env.gitlab_qa_1p_password
          @secret = QA::Runtime::Env.gitlab_qa_1p_secret
          @github_uuid = QA::Runtime::Env.gitlab_qa_1p_github_uuid
        end

        def fresh_otp
          otps = []

          # Fetches a fresh OTP and returns it only after op provides the same OTP twice
          # An OTP is valid for 30 seconds so 70 attempts with 0.5 interval would ensure we complete 1 cycle
          Support::Retrier.retry_until(max_attempts: 70, sleep_interval: 0.5) do
            otps << fetch_otp
            otps.size >= 3 && otps[-1] == otps[-2] && otps[-1] != otps[-3]
          end

          otps.last
        end

        private

        def fetch_otp
          result = nil

          time = Benchmark.realtime do
            result = `#{op_path} get totp #{@github_uuid} --session=#{session_token}`.to_i
          end

          QA::Runtime::Logger.info("Fetched OTP: #{result} in: #{time} seconds")

          result
        end

        # OP session tokens are valid for 30 minutes. We are caching the session token here and this is fine currently
        # as we just have one test that is not expected to go over 30 minutes.
        # But note that if we add more tests that use this class, we might need to add a mechanism to invalidate
        # the cache after 30 minutes or if the session_token is rejected by op CLI.
        def session_token
          @session_token ||= `echo '#{@password}' | #{op_path} signin gitlab.1password.com #{@email} #{@secret} --output=raw --shorthand=gitlab_qa`
        end

        def op_path
          File.expand_path(File.join(%W[qa vendor one_password #{os} op]))
        end

        def os
          RUBY_PLATFORM.include?("darwin") ? "darwin" : "linux"
        end
      end
    end
  end
end

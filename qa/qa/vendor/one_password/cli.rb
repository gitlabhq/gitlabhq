# frozen_string_literal: true

module QA
  module Vendor
    module OnePassword
      class CLI
        def initialize
          @email = QA::Runtime::Env.gitlab_qa_1p_email
          @password = QA::Runtime::Env.gitlab_qa_1p_password
          @secret = QA::Runtime::Env.gitlab_qa_1p_secret
          @github_uuid = QA::Runtime::Env.gitlab_qa_1p_github_uuid
        end

        def otp
          `#{op_path} get totp #{@github_uuid} --session=#{session_token}`.to_i
        end

        private

        def session_token
          `echo '#{@password}' | #{op_path} signin gitlab.1password.com #{@email} #{@secret} --output=raw --shorthand=gitlab_qa`
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

# frozen_string_literal: true

module QA
  module Tools
    # Task to set default password from Runtime::Env.default_password if not set already
    # Also creates a personal access token
    # @example
    #   $ bundle exec rake  'initialize_gitlab_auth[http://gitlab.test]'
    class InitializeGitlabAuth
      attr_reader :address

      def initialize(address:)
        @address = address
      end

      def run
        Runtime::Scenario.define(:gitlab_address, address)

        QA::Runtime::Logger.info("Signing in and creating the default password for the root user if it's not set already...")
        QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
        Flow::Login.sign_in

        puts "Creating an API scoped access token for the root user..."
        puts "Token: #{Resource::PersonalAccessToken.fabricate!.token}"
      end
    end
  end
end

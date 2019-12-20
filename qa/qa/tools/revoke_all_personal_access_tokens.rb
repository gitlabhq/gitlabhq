# frozen_string_literal: true

require_relative '../../qa'
require 'net/protocol.rb'
# This script revokes all personal access tokens with the name of 'api-test-token' on the host specified by GITLAB_ADDRESS
# Required environment variables: GITLAB_USERNAME, GITLAB_PASSWORD and GITLAB_ADDRESS
# Run `rake revoke_personal_access_tokens`

module QA
  module Tools
    class RevokeAllPersonalAccessTokens
      def run
        do_run
      rescue Net::ReadTimeout
        STDOUT.puts 'Net::ReadTimeout during run. Trying again'
        run
      end

      private

      def do_run
        raise ArgumentError, "Please provide GITLAB_USERNAME" unless ENV['GITLAB_USERNAME']
        raise ArgumentError, "Please provide GITLAB_PASSWORD" unless ENV['GITLAB_PASSWORD']
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']

        STDOUT.puts 'Running...'

        Runtime::Browser.visit(ENV['GITLAB_ADDRESS'], Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_access_tokens)

        token_name = 'api-test-token'

        Page::Profile::PersonalAccessTokens.perform do |tokens_page|
          while tokens_page.has_token_row_for_name?(token_name)
            tokens_page.revoke_first_token_with_name(token_name)
            print "\e[32m.\e[0m"
          end
        end
      end
    end
  end
end

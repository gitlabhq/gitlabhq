# frozen_string_literal: true

module QA
  module Runtime
    module Env
      extend self

      attr_writer :personal_access_token

      def debug?
        enabled?(ENV['QA_DEBUG'], default: false)
      end

      def log_destination
        ENV['QA_LOG_PATH'] || $stdout
      end

      # set to 'false' to have Chrome run visibly instead of headless
      def chrome_headless?
        enabled?(ENV['CHROME_HEADLESS'])
      end

      def accept_insecure_certs?
        enabled?(ENV['ACCEPT_INSECURE_CERTS'])
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      def signup_disabled?
        enabled?(ENV['SIGNUP_DISABLED'], default: false)
      end

      # specifies token that can be used for the api
      def personal_access_token
        @personal_access_token ||= ENV['PERSONAL_ACCESS_TOKEN']
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def admin_username
        ENV['GITLAB_ADMIN_USERNAME']
      end

      def admin_password
        ENV['GITLAB_ADMIN_PASSWORD']
      end

      def forker?
        !!(forker_username && forker_password)
      end

      def forker_username
        ENV['GITLAB_FORKER_USERNAME']
      end

      def forker_password
        ENV['GITLAB_FORKER_PASSWORD']
      end

      def ldap_username
        ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_password
        ENV['GITLAB_LDAP_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end

      def gcloud_account_key
        ENV.fetch("GCLOUD_ACCOUNT_KEY")
      end

      def gcloud_account_email
        ENV.fetch("GCLOUD_ACCOUNT_EMAIL")
      end

      def gcloud_zone
        ENV.fetch('GCLOUD_ZONE')
      end

      def has_gcloud_credentials?
        %w[GCLOUD_ACCOUNT_KEY GCLOUD_ACCOUNT_EMAIL].none? { |var| ENV[var].to_s.empty? }
      end

      # Specifies the token that can be used for the GitHub API
      def github_access_token
        ENV['GITHUB_ACCESS_TOKEN'].to_s.strip
      end

      def require_github_access_token!
        return unless github_access_token.empty?

        raise ArgumentError, "Please provide GITHUB_ACCESS_TOKEN"
      end

      private

      def enabled?(value, default: true)
        return default if value.nil?

        (value =~ /^(false|no|0)$/i) != 0
      end
    end
  end
end

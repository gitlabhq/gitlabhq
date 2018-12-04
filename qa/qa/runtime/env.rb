# frozen_string_literal: true

module QA
  module Runtime
    module Env
      extend self

      attr_writer :personal_access_token, :ldap_username, :ldap_password

      # The environment variables used to indicate if the environment under test
      # supports the given feature
      SUPPORTED_FEATURES = {
        git_protocol_v2: 'QA_CAN_TEST_GIT_PROTOCOL_V2'
      }.freeze

      def supported_features
        SUPPORTED_FEATURES
      end

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

      def qa_cookies
        ENV['QA_COOKIES'] && ENV['QA_COOKIES'].split(';')
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

      def gitlab_qa_username_1
        ENV['GITLAB_QA_USERNAME_1'] || 'gitlab-qa-user1'
      end

      def gitlab_qa_password_1
        ENV['GITLAB_QA_PASSWORD_1']
      end

      def gitlab_qa_username_2
        ENV['GITLAB_QA_USERNAME_2'] || 'gitlab-qa-user2'
      end

      def gitlab_qa_password_2
        ENV['GITLAB_QA_PASSWORD_2']
      end

      def ldap_username
        @ldap_username ||= ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_password
        @ldap_password ||= ENV['GITLAB_LDAP_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end

      def namespace_name
        ENV['GITLAB_NAMESPACE_NAME']
      end

      def auto_devops_project_name
        ENV['GITLAB_AUTO_DEVOPS_PROJECT_NAME']
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

      # Returns true if there is an environment variable that indicates that
      # the feature is supported in the environment under test.
      # All features are supported by default.
      def can_test?(feature)
        raise ArgumentError, %Q(Unknown feature "#{feature}") unless SUPPORTED_FEATURES.include? feature

        enabled?(ENV[SUPPORTED_FEATURES[feature]], default: true)
      end

      private

      def enabled?(value, default: true)
        return default if value.nil?

        (value =~ /^(false|no|0)$/i) != 0
      end
    end
  end
end

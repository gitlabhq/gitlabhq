module QA
  module Runtime
    module Env
      prepend QA::EE::Runtime::Env

      extend self

      attr_writer :user_type

      # set to 'false' to have Chrome run visibly instead of headless
      def chrome_headless?
        (ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i) != 0
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      # specifies token that can be used for the api
      def personal_access_token
        ENV['PERSONAL_ACCESS_TOKEN']
      end

      # By default, "standard" denotes a standard GitLab user login.
      # Set this to "ldap" if the user should be logged in via LDAP.
      def user_type
        return @user_type if defined?(@user_type) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        ENV.fetch('GITLAB_USER_TYPE', 'standard').tap do |type|
          unless %w(ldap standard).include?(type)
            raise ArgumentError.new("Invalid user type '#{type}': must be 'ldap' or 'standard'")
          end
        end
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def forker?
        forker_username && forker_password
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
    end
  end
end

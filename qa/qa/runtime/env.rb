module QA
  module Runtime
    module Env
      extend self

      # specifies token that can be used for the api
      def personal_access_token
        ENV['PERSONAL_ACCESS_TOKEN']
      end

      # By default, "standard" denotes a standard GitLab user login.
      # Set this to "ldap" if the user should be logged in via LDAP.
      def user_type
        (ENV['GITLAB_USER_TYPE'] || 'standard').tap do |type|
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

      def ldap_username
        ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_password
        ENV['GITLAB_LDAP_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end
    end
  end
end

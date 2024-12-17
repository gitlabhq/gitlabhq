# frozen_string_literal: true

module QA
  module Runtime
    module User
      # Helper module for accessing test user related predefined credentials
      #
      module Data
        # @return [String] admin api token variable name
        ADMIN_API_TOKEN_VARIABLE = "GITLAB_QA_ADMIN_ACCESS_TOKEN"
        # @return [String] default admin api token pre-seeded on ephemeral test environments
        DEFAULT_ADMIN_API_TOKEN = "ypCa3Dzb23o5nvsixwPA" # gitleaks:allow
        # @return [String] admin username variable name
        ADMIN_USERNAME_VARIABLE_NAME = "GITLAB_ADMIN_USERNAME"
        # @return [String] default username for admin user
        DEFAULT_ADMIN_USERNAME = "root"
        # @return [String] admin password variable name
        ADMIN_PASSWORD_VARIABLE_NAME = "GITLAB_ADMIN_PASSWORD"
        # @return [String] default password for admin user
        DEFAULT_ADMIN_PASSWORD = "5iveL!fe"

        # @return [String] global test user api token
        TEST_USER_API_TOKEN_VARIABLE_NAME = "GITLAB_QA_ACCESS_TOKEN"
        # @return [String] global test user username
        TEST_USER_USERNAME_VARIABLE_NAME = "GITLAB_USERNAME"
        # @return [String] global test user password
        TEST_USER_PASSWORD_VARIABLE_NAME = "GITLAB_PASSWORD"

        # @return [String] extra test user username environment variable name
        ADDITIONAL_TEST_USERNAME_VARIABLE_NAME = "GITLAB_QA_USERNAME_1"
        # @return [String] extra test user password environment variable name
        ADDITIONAL_TEST_PASSWORD_VARIABLE_NAME = "GITLAB_QA_PASSWORD_1"

        # Admin user username
        #
        # @return [String]
        def admin_username
          @admin_username ||= admin_variable_with_default(
            "username",
            ADMIN_USERNAME_VARIABLE_NAME,
            DEFAULT_ADMIN_USERNAME
          )
        end

        # Admin user password
        #
        # @return [String]
        def admin_password
          @admin_password ||= admin_variable_with_default(
            "password",
            ADMIN_PASSWORD_VARIABLE_NAME,
            DEFAULT_ADMIN_PASSWORD
          )
        end

        # Admin api token
        #
        # @return [String]
        def admin_api_token
          @admin_api_token ||= ENV[ADMIN_API_TOKEN_VARIABLE]
        end
        module_function :admin_api_token

        # Global test user username
        #
        # @return [String]
        def test_user_username
          ENV[TEST_USER_USERNAME_VARIABLE_NAME]
        end

        # Global test user password
        #
        # @return [String]
        def test_user_password
          ENV[TEST_USER_PASSWORD_VARIABLE_NAME]
        end

        # Global test user api token
        #
        # @return [String]
        def test_user_api_token
          ENV[TEST_USER_API_TOKEN_VARIABLE_NAME]
        end
        module_function :test_user_api_token

        # LDAP user username
        #
        # @return [String]
        def ldap_username
          ENV["GITLAB_LDAP_USERNAME"]
        end

        # LDAP user password
        #
        # @return [String]
        def ldap_password
          ENV["GITLAB_LDAP_PASSWORD"]
        end

        private

        # Admin user related variable with default value
        #
        # @param type [String]
        # @param var_name [String]
        # @param default [String]
        # @return [String]
        def admin_variable_with_default(type, var_name, default)
          ENV[var_name].then do |value|
            next value unless value.blank?

            Logger.warn("Admin #{type} variable '#{var_name}' not set, using default value!")
            default
          end
        end
      end
    end
  end
end

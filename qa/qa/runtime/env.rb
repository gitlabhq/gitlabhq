# frozen_string_literal: true

require 'active_support/deprecation'
require 'gitlab/qa'
require 'uri'

module QA
  module Runtime
    module Env
      extend self

      attr_writer :personal_access_token, :admin_personal_access_token

      ENV_VARIABLES = Gitlab::QA::Runtime::Env::ENV_VARIABLES

      # The environment variables used to indicate if the environment under test
      # supports the given feature
      SUPPORTED_FEATURES = {
        git_protocol_v2: 'QA_CAN_TEST_GIT_PROTOCOL_V2',
        admin: 'QA_CAN_TEST_ADMIN_FEATURES',
        praefect: 'QA_CAN_TEST_PRAEFECT'
      }.freeze

      def supported_features
        SUPPORTED_FEATURES
      end

      def additional_repository_storage
        ENV['QA_ADDITIONAL_REPOSITORY_STORAGE']
      end

      def non_cluster_repository_storage
        ENV['QA_GITALY_NON_CLUSTER_STORAGE'] || 'gitaly'
      end

      def praefect_repository_storage
        ENV['QA_PRAEFECT_REPOSITORY_STORAGE']
      end

      def ci_job_url
        ENV['CI_JOB_URL']
      end

      def ci_job_name
        ENV['CI_JOB_NAME']
      end

      def ci_project_name
        ENV['CI_PROJECT_NAME']
      end

      def debug?
        enabled?(ENV['QA_DEBUG'], default: false)
      end

      def generate_allure_report?
        enabled?(ENV['QA_GENERATE_ALLURE_REPORT'], default: false)
      end

      def default_branch
        ENV['QA_DEFAULT_BRANCH'] || 'main'
      end

      def log_destination
        ENV['QA_LOG_PATH'] || $stdout
      end

      # set to 'false' to have the browser run visibly instead of headless
      def webdriver_headless?
        if ENV.key?('CHROME_HEADLESS')
          ActiveSupport::Deprecation.warn("CHROME_HEADLESS is deprecated. Use WEBDRIVER_HEADLESS instead.")
        end

        enabled?(ENV['WEBDRIVER_HEADLESS']) || enabled?(ENV['CHROME_HEADLESS'])
      end

      # set to 'true' to have Chrome use a fixed profile directory
      def reuse_chrome_profile?
        enabled?(ENV['CHROME_REUSE_PROFILE'], default: false)
      end

      def accept_insecure_certs?
        enabled?(ENV['ACCEPT_INSECURE_CERTS'])
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      def cluster_api_url
        ENV['CLUSTER_API_URL']
      end

      def qa_cookies
        ENV['QA_COOKIES'] && ENV['QA_COOKIES'].split(';')
      end

      def signup_disabled?
        enabled?(ENV['SIGNUP_DISABLED'], default: false)
      end

      def admin_password
        ENV['GITLAB_ADMIN_PASSWORD']
      end

      def admin_username
        ENV['GITLAB_ADMIN_USERNAME']
      end

      def admin_personal_access_token
        @admin_personal_access_token ||= ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN']
      end

      # specifies token that can be used for the api
      def personal_access_token
        @personal_access_token ||= ENV['GITLAB_QA_ACCESS_TOKEN']
      end

      def remote_grid
        # if username specified, password/auth token is required
        # can be
        # - "http://user:pass@somehost.com/wd/hub"
        # - "https://user:pass@somehost.com:443/wd/hub"
        # - "http://localhost:4444/wd/hub"

        return if (ENV['QA_REMOTE_GRID'] || '').empty?

        "#{remote_grid_protocol}://#{remote_grid_credentials}#{ENV['QA_REMOTE_GRID']}/wd/hub"
      end

      def remote_grid_username
        ENV['QA_REMOTE_GRID_USERNAME']
      end

      def remote_grid_access_key
        ENV['QA_REMOTE_GRID_ACCESS_KEY']
      end

      def remote_grid_protocol
        ENV['QA_REMOTE_GRID_PROTOCOL'] || 'http'
      end

      def browser
        ENV['QA_BROWSER'].nil? ? :chrome : ENV['QA_BROWSER'].to_sym
      end

      def remote_mobile_device_name
        ENV['QA_REMOTE_MOBILE_DEVICE_NAME']
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def initial_root_password
        ENV['GITLAB_INITIAL_ROOT_PASSWORD']
      end

      def github_username
        ENV['GITHUB_USERNAME']
      end

      def github_password
        ENV['GITHUB_PASSWORD']
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

      def gitlab_qa_username_3
        ENV['GITLAB_QA_USERNAME_3'] || 'gitlab-qa-user3'
      end

      def gitlab_qa_password_3
        ENV['GITLAB_QA_PASSWORD_3']
      end

      def gitlab_qa_username_4
        ENV['GITLAB_QA_USERNAME_4'] || 'gitlab-qa-user4'
      end

      def gitlab_qa_password_4
        ENV['GITLAB_QA_PASSWORD_4']
      end

      def gitlab_qa_username_5
        ENV['GITLAB_QA_USERNAME_5'] || 'gitlab-qa-user5'
      end

      def gitlab_qa_password_5
        ENV['GITLAB_QA_PASSWORD_5']
      end

      def gitlab_qa_username_6
        ENV['GITLAB_QA_USERNAME_6'] || 'gitlab-qa-user6'
      end

      def gitlab_qa_password_6
        ENV['GITLAB_QA_PASSWORD_6']
      end

      def gitlab_qa_2fa_owner_username_1
        ENV['GITLAB_QA_2FA_OWNER_USERNAME_1'] || 'gitlab-qa-2fa-owner-user1'
      end

      def gitlab_qa_2fa_owner_password_1
        ENV['GITLAB_QA_2FA_OWNER_PASSWORD_1']
      end

      def gitlab_qa_1p_email
        ENV['GITLAB_QA_1P_EMAIL']
      end

      def gitlab_qa_1p_password
        ENV['GITLAB_QA_1P_PASSWORD']
      end

      def gitlab_qa_1p_secret
        ENV['GITLAB_QA_1P_SECRET']
      end

      def gitlab_qa_1p_github_uuid
        ENV['GITLAB_QA_1P_GITHUB_UUID']
      end

      def jira_admin_username
        ENV['JIRA_ADMIN_USERNAME']
      end

      def jira_admin_password
        ENV['JIRA_ADMIN_PASSWORD']
      end

      def jira_hostname
        ENV['JIRA_HOSTNAME']
      end

      def cache_namespace_name?
        enabled?(ENV['CACHE_NAMESPACE_NAME'], default: true)
      end

      def knapsack?
        !!(ENV['KNAPSACK_GENERATE_REPORT'] || ENV['KNAPSACK_REPORT_PATH'] || ENV['KNAPSACK_TEST_FILE_PATTERN'])
      end

      def ldap_username
        @ldap_username ||= ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_username=(ldap_username)
        @ldap_username = ldap_username # rubocop:disable Gitlab/ModuleWithInstanceVariables
        ENV['GITLAB_LDAP_USERNAME'] = ldap_username
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

      def gcloud_region
        ENV['GCLOUD_REGION']
      end

      def gcloud_num_nodes
        ENV.fetch('GCLOUD_NUM_NODES', 1)
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

      def require_admin_access_token!
        admin_personal_access_token || (raise ArgumentError, "GITLAB_QA_ADMIN_ACCESS_TOKEN is required!")
      end

      # Returns true if there is an environment variable that indicates that
      # the feature is supported in the environment under test.
      # All features are supported by default.
      def can_test?(feature)
        raise ArgumentError, %Q(Unknown feature "#{feature}") unless SUPPORTED_FEATURES.include? feature

        enabled?(ENV[SUPPORTED_FEATURES[feature]], default: true)
      end

      def runtime_scenario_attributes
        ENV['QA_RUNTIME_SCENARIO_ATTRIBUTES']
      end

      def disable_rspec_retry?
        enabled?(ENV['QA_DISABLE_RSPEC_RETRY'], default: false)
      end

      def simulate_slow_connection?
        enabled?(ENV['QA_SIMULATE_SLOW_CONNECTION'], default: false)
      end

      def slow_connection_latency
        ENV.fetch('QA_SLOW_CONNECTION_LATENCY_MS', 2000).to_i
      end

      def slow_connection_throughput
        ENV.fetch('QA_SLOW_CONNECTION_THROUGHPUT_KBPS', 32).to_i
      end

      def gitlab_qa_loop_runner_minutes
        ENV.fetch('GITLAB_QA_LOOP_RUNNER_MINUTES', 1).to_i
      end

      def mailhog_hostname
        ENV['MAILHOG_HOSTNAME']
      end

      # Get the version of GitLab currently being tested against
      # @return String Version
      # @example
      #   > Env.deploy_version
      #   #=> 13.3.4-ee.0
      def deploy_version
        ENV['DEPLOY_VERSION']
      end

      def user_agent
        ENV['GITLAB_QA_USER_AGENT']
      end

      def geo_environment?
        QA::Runtime::Scenario.attributes.include?(:geo_secondary_address)
      end

      def gitlab_agentk_version
        ENV.fetch('GITLAB_AGENTK_VERSION', 'v13.7.0')
      end

      def transient_trials
        ENV.fetch('GITLAB_QA_TRANSIENT_TRIALS', 10).to_i
      end

      private

      def remote_grid_credentials
        if remote_grid_username
          raise ArgumentError, %Q(Please provide an access key for user "#{remote_grid_username}") unless remote_grid_access_key

          return "#{remote_grid_username}:#{remote_grid_access_key}@"
        end

        ''
      end

      def enabled?(value, default: true)
        return default if value.nil?

        (value =~ /^(false|no|0)$/i) != 0
      end
    end
  end
end

QA::Runtime::Env.extend_mod_with('Runtime::Env', namespace: QA)

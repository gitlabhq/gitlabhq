# frozen_string_literal: true

require 'active_support/deprecation'
require 'uri'
require 'etc'

module QA
  module Runtime
    module Env
      extend self

      attr_writer :gitlab_url

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

      def gitlab_url
        @gitlab_url ||= ENV["QA_GITLAB_URL"] || "http://127.0.0.1:3000" # default to GDK
      end

      # Retrieves the value of the gitlab_canary cookie if set or returns an empty hash.
      #
      # @return [Hash]
      def canary_cookie
        canary = ENV['QA_COOKIES']&.scan(/gitlab_canary=(true|false)/)&.dig(0, 0)

        canary ? { gitlab_canary: canary } : {}
      end

      def additional_repository_storage
        ENV['QA_ADDITIONAL_REPOSITORY_STORAGE'] || 'secondary'
      end

      def non_cluster_repository_storage
        ENV['QA_GITALY_NON_CLUSTER_STORAGE'] || 'gitaly'
      end

      def praefect_repository_storage
        ENV['QA_PRAEFECT_REPOSITORY_STORAGE'] || 'default'
      end

      def interception_enabled?
        enabled?(ENV['QA_INTERCEPT_REQUESTS'], default: false)
      end

      def can_intercept?
        browser == :chrome && interception_enabled?
      end

      def release
        ENV['RELEASE']
      end

      def release_registry_url
        ENV['RELEASE_REGISTRY_URL']
      end

      def release_registry_username
        ENV['RELEASE_REGISTRY_USERNAME']
      end

      def release_registry_password
        ENV['RELEASE_REGISTRY_PASSWORD']
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

      def ci_project_path
        ENV['CI_PROJECT_PATH']
      end

      def ci_project_dir
        ENV.fetch('CI_PROJECT_DIR')
      end

      def coverband_enabled?
        enabled?(ENV['COVERBAND_ENABLED'], default: false)
      end

      def selective_execution_improved_enabled?
        enabled?(ENV['SELECTIVE_EXECUTION_IMPROVED'], default: false)
      end

      def mr_targeting_stable_branch?
        /^[\d-]+-stable(-ee|-jh)?$/.match?(ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || "")
      end

      def schedule_type
        ENV['SCHEDULE_TYPE']
      end

      def generate_allure_report?
        enabled?(ENV['QA_GENERATE_ALLURE_REPORT'], default: false)
      end

      def default_branch
        ENV['QA_DEFAULT_BRANCH'] || 'main'
      end

      def colorized_logs?
        enabled?(ENV['COLORIZED_LOGS'], default: false)
      end

      # set to 'false' to have the browser run visibly instead of headless
      def webdriver_headless?
        if ENV.key?('CHROME_HEADLESS')
          ActiveSupport::Deprecation.warn("CHROME_HEADLESS is deprecated. Use WEBDRIVER_HEADLESS instead.")
        end

        return enabled?(ENV['WEBDRIVER_HEADLESS']) unless ENV['WEBDRIVER_HEADLESS'].nil?

        enabled?(ENV['CHROME_HEADLESS'])
      end

      # set to 'true' to have Chrome use a fixed profile directory
      def reuse_chrome_profile?
        enabled?(ENV['CHROME_REUSE_PROFILE'], default: false)
      end

      # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
      def disable_dev_shm?
        running_in_ci? || enabled?(ENV['CHROME_DISABLE_DEV_SHM'], default: false)
      end

      def accept_insecure_certs?
        enabled?(ENV['ACCEPT_INSECURE_CERTS'])
      end

      def running_on_live_env?
        running_on_dot_com? || running_on_release?
      end

      def running_on_dot_com?
        gitlab_host.include?('.com')
      end

      def running_on_release?
        gitlab_host.include?('release.gitlab.net')
      end

      def running_on_dev?
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        uri.port != 80 && uri.port != 443
      end

      def running_on_dev_or_dot_com?
        running_on_dev? || running_on_dot_com?
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

      # PATs are disabled for FedRamp
      def personal_access_tokens_disabled?
        enabled?(ENV['PERSONAL_ACCESS_TOKENS_DISABLED'], default: false)
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

      def remote_tunnel_id
        ENV['QA_REMOTE_TUNNEL_ID'] || 'gitlab-sl_tunnel_id'
      end

      def browser
        ENV['QA_BROWSER'].nil? ? :chrome : ENV['QA_BROWSER'].to_sym
      end

      def selenoid_browser_version
        ENV['QA_SELENOID_BROWSER_VERSION']
      end

      def selenoid_browser_image
        ENV['QA_SELENOID_BROWSER_IMAGE']
      end

      def video_recorder_image
        ENV['QA_VIDEO_RECORDER_IMAGE']
      end

      def remote_mobile_device_name
        ENV['QA_REMOTE_MOBILE_DEVICE_NAME']&.downcase
      end

      def layout
        ENV['QA_LAYOUT']&.downcase || ''
      end

      def tablet_layout?
        return true if remote_mobile_device_name && !phone_layout?

        layout.include?('tablet')
      end

      def phone_layout?
        return true if layout.include?('phone')

        return false unless remote_mobile_device_name

        !(remote_mobile_device_name.include?('ipad') || remote_mobile_device_name.include?('tablet'))
      end

      def mobile_layout?
        phone_layout? || tablet_layout? || remote_mobile_device_name
      end

      def record_video?
        enabled?(ENV['QA_RECORD_VIDEO'], default: false)
      end

      def use_selenoid?
        enabled?(ENV['USE_SELENOID'], default: false)
      end

      def use_sha256_repository_object_storage
        enabled?(ENV['QA_USE_SHA256_REPOSITORY_OBJECT_STORAGE'], default: false)
      end

      def save_all_videos?
        enabled?(ENV['QA_SAVE_ALL_VIDEOS'], default: false)
      end

      def require_video_variables!
        docs_link = 'https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/running_against_remote_grid.md#testing-with-selenoid'
        use_selenoid? || (raise ArgumentError, "USE_SELENOID is required! See docs: #{docs_link}")
        remote_grid || (raise ArgumentError, "QA_REMOTE_GRID is required! See docs: #{docs_link}")
        video_recorder_image || (raise ArgumentError, "QA_VIDEO_RECORDER_IMAGE is required! See docs: #{docs_link}")
        selenoid_browser_image || (raise ArgumentError, "QA_SELENOID_BROWSER_IMAGE is required! See docs: #{docs_link}")
        selenoid_browser_version || (raise ArgumentError,
          "QA_SELENOID_BROWSER_VERSION is required! See docs: #{docs_link}")
      end

      def github_username
        ENV['QA_GITHUB_USERNAME']
      end

      def github_password
        ENV['QA_GITHUB_PASSWORD']
      end

      def jira_admin_username
        ENV['QA_JIRA_ADMIN_USERNAME']
      end

      def jira_admin_password
        ENV['QA_JIRA_ADMIN_PASSWORD']
      end

      def jira_hostname
        ENV['JIRA_HOSTNAME']
      end

      def slack_workspace
        ENV['QA_SLACK_WORKSPACE']
      end

      def slack_email
        ENV['QA_SLACK_EMAIL']
      end

      def slack_password
        ENV['QA_SLACK_PASSWORD']
      end

      def jenkins_admin_username
        ENV.fetch('QA_JENKINS_USER', 'administrator')
      end

      def jenkins_admin_password
        ENV.fetch('QA_JENKINS_PASS', 'password')
      end

      # this is set by the integrations job
      # which will allow bidirectional communication
      # between the app and the specs container
      # should the specs container spin up a server
      def qa_hostname
        ENV['QA_HOSTNAME']
      end

      def knapsack?
        ENV['CI_NODE_TOTAL'].to_i > 1 && ENV['NO_KNAPSACK'] != "true"
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

      # ENV variables for workspaces to run against existing cluster or creating new cluster
      def workspaces_cluster_available?
        enabled?(ENV['WORKSPACES_CLUSTER_AVAILABLE'], default: false)
      end

      def workspaces_cluster_name
        ENV.fetch("WORKSPACES_CLUSTER_NAME")
      end

      def workspaces_cluster_region
        ENV.fetch("WORKSPACES_CLUSTER_REGION")
      end

      # ENV variables for workspaces OAuth App and the domain
      def workspaces_oauth_app_id
        ENV.fetch("WORKSPACES_OAUTH_APP_ID")
      end

      def workspaces_oauth_app_secret
        ENV.fetch("WORKSPACES_OAUTH_APP_SECRET")
      end

      def workspaces_oauth_signing_key
        ENV.fetch("WORKSPACES_OAUTH_SIGNING_KEY")
      end

      def workspaces_proxy_version
        ENV.fetch("WORKSPACES_PROXY_VERSION", '0.1.12')
      end

      def workspaces_proxy_domain
        ENV.fetch("WORKSPACES_PROXY_DOMAIN")
      end

      def workspaces_domain_cert
        ENV.fetch("WORKSPACES_DOMAIN_CERT")
      end

      def workspaces_domain_key
        ENV.fetch("WORKSPACES_DOMAIN_KEY")
      end

      def workspaces_wildcard_cert
        ENV.fetch("WORKSPACES_WILDCARD_CERT")
      end

      def workspaces_wildcard_key
        ENV.fetch("WORKSPACES_WILDCARD_KEY")
      end

      # Specifies the token that can be used for the GitHub API
      def github_access_token
        ENV['QA_GITHUB_ACCESS_TOKEN'].to_s.strip
      end

      def require_github_access_token!
        return unless github_access_token.empty?

        raise ArgumentError, "Please provide QA_GITHUB_ACCESS_TOKEN"
      end

      # Returns true if there is an environment variable that indicates that
      # the feature is supported in the environment under test.
      # All features are supported by default.
      def can_test?(feature)
        raise ArgumentError, %(Unknown feature "#{feature}") unless SUPPORTED_FEATURES.include? feature

        enabled?(ENV[SUPPORTED_FEATURES[feature]], default: true)
      end

      def runtime_scenario_attributes
        ENV['QA_RUNTIME_SCENARIO_ATTRIBUTES']
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

      def gitlab_tls_certificate
        ENV['GITLAB_TLS_CERTIFICATE']
      end

      def export_metrics?
        enabled?(ENV['QA_EXPORT_TEST_METRICS'], default: false)
      end

      def save_metrics_json?
        enabled?(ENV['QA_SAVE_TEST_METRICS'], default: false)
      end

      def ee_license
        return ENV["QA_EE_LICENSE"] if ENV["QA_EE_LICENSE"]

        ENV["EE_LICENSE"].tap do |license|
          next unless license

          Runtime::Logger.warn("EE_LICENSE environment variable is deprecated, please use QA_EE_LICENSE instead!")
        end
      end

      def ee_activation_code
        ENV['QA_EE_ACTIVATION_CODE']
      end

      def quarantine_disabled?
        enabled?(ENV['DISABLE_QUARANTINE'], default: false)
      end

      def validate_resource_reuse?
        enabled?(ENV['QA_VALIDATE_RESOURCE_REUSE'], default: false)
      end

      def fips?
        enabled?(ENV['FIPS'], default: false)
      end

      def container_registry_host
        ENV.fetch('QA_CONTAINER_REGISTRY_HOST', 'registry.gitlab.com')
      end

      def runner_container_image
        ENV.fetch('QA_RUNNER_CONTAINER_IMAGE', 'gitlab-runner:alpine')
      end

      def runner_container_namespace
        ENV['QA_RUNNER_CONTAINER_NAMESPACE'] || 'gitlab-org'
      end

      def gitlab_qa_build_image
        ENV['QA_GITLAB_QA_BUILD_IMAGE'] || 'gitlab-build-images:gitlab-qa-alpine-ruby-2.7'
      end

      # ENV variables for authenticating against a private container registry
      # These need to be set if using the
      # Service::DockerRun::Mixins::ThirdPartyDocker module
      def third_party_docker_registry
        ENV['QA_THIRD_PARTY_DOCKER_REGISTRY']
      end

      def third_party_docker_repository
        ENV['QA_THIRD_PARTY_DOCKER_REPOSITORY']
      end

      def third_party_docker_user
        ENV['QA_THIRD_PARTY_DOCKER_USER']
      end

      def third_party_docker_password
        ENV['QA_THIRD_PARTY_DOCKER_PASSWORD']
      end

      def max_capybara_wait_time
        ENV.fetch('MAX_CAPYBARA_WAIT_TIME', 10).to_i
      end

      def use_public_ip_api?
        enabled?(ENV['QA_USE_PUBLIC_IP_API'], default: false)
      end

      def allow_local_requests?
        enabled?(ENV['QA_ALLOW_LOCAL_REQUESTS'], default: false)
      end

      def chrome_default_download_path
        ENV['DEFAULT_CHROME_DOWNLOAD_PATH'] || Dir.tmpdir
      end

      def require_slack_env!
        missing_env = %i[slack_workspace slack_email slack_password].select do |method|
          ::QA::Runtime::Env.public_send(method).nil?
        end
        return unless missing_env.any?

        raise "Missing Slack env: #{missing_env.map(&:upcase).join(', ')}"
      end

      def one_p_email
        ENV['QA_1P_EMAIL']
      end

      def one_p_password
        ENV['QA_1P_PASSWORD']
      end

      def one_p_secret
        ENV['QA_1P_SECRET']
      end

      def one_p_github_uuid
        ENV['QA_1P_GITHUB_UUID']
      end

      # Docker network to use when starting sidecar containers
      #
      # @return [String]
      def docker_network
        ENV["QA_DOCKER_NETWORK"]
      end

      # Product analytics configurator string (e.g. https://usr:pass@gl-configurator.gitlab.com)
      #
      # @return [String]
      def pa_configurator_url
        ENV['PA_CONFIGURATOR_URL']
      end

      # Product analytics collector url (e.g. https://collector.gitlab.com)
      #
      # @return [String]
      def pa_collector_host
        ENV['PA_COLLECTOR_HOST']
      end

      # Product analytics cube api url (e.g. https://cube.gitlab.com)
      #
      # @return [String]
      def pa_cube_api_url
        ENV['PA_CUBE_API_URL']
      end

      # Product analytics cube api key
      #
      # @return [String]
      def pa_cube_api_key
        ENV['PA_CUBE_API_KEY']
      end

      # Test run is in rspec retried process
      #
      # @return [Boolean]
      def rspec_retried?
        enabled?(ENV['QA_RSPEC_RETRIED'], default: false)
      end

      def parallel_processes
        ENV.fetch('QA_PARALLEL_PROCESSES') do
          [Etc.nprocessors / 2, 1].max
        end.to_i
      end

      # Execution was started by parallel runner
      #
      # @return [Boolean]
      def parallel_run?
        ENV["TEST_ENV_NUMBER"].present?
      end

      # Execute tests in multiple parallel processes
      #
      # @return [Boolean]
      def run_in_parallel?
        enabled?(ENV["QA_RUN_IN_PARALLEL"], default: false)
      end

      # Environment has no support for admin operations
      #
      # @return [Boolean]
      def no_admin_environment?
        enabled?(ENV["QA_NO_ADMIN_ENV"], default: false) || gitlab_host == "gitlab.com"
      end

      # Test run type
      #
      # @return [String]
      def run_type
        ENV["QA_RUN_TYPE"].presence
      end

      # Execution performed with --dry-run flag
      #
      # @return [Boolean]
      def dry_run
        enabled?(ENV["QA_RSPEC_DRY_RUN"], default: false)
      end

      # Ignore runtime data when generating knapsack reports
      #
      # @return [Boolean]
      def ignore_runtime_data?
        enabled?(ENV["QA_IGNORE_RUNTIME_DATA"], default: false)
      end

      # Create uniq test users for each test
      #
      # @return [Boolean]
      def create_unique_test_users?
        enabled?(ENV["QA_CREATE_UNIQUE_TEST_USERS"], default: true)
      end

      private

      # Gitlab host tests are running against
      #
      # @return [String]
      def gitlab_host
        # gitlab address should be immutable so it's ok to memoize as global
        @gitlab_host ||= URI.parse(Runtime::Scenario.gitlab_address).host
      end

      def remote_grid_credentials
        if remote_grid_username
          unless remote_grid_access_key
            raise ArgumentError, %(Please provide an access key for user "#{remote_grid_username}")
          end

          return "#{remote_grid_username}:#{remote_grid_access_key}@"
        end

        ''
      end

      def enabled?(value, default: true)
        return default if value.nil?

        value.to_s.match?(/^(true|yes|1)$/i)
      end
    end
  end
end

QA::Runtime::Env.extend_mod_with('Runtime::Env', namespace: QA)

# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/hash"

module Gitlab
  module Cng
    module Deployment
      # Class handling all the pre and post deployment setup steps and gitlab helm chart installation
      #
      class Installation
        include Helpers::Output
        include Helpers::Shell
        extend Helpers::Output
        extend Helpers::Shell

        LICENSE_SECRET = "gitlab-license"
        TROUBLESHOOTING_LINK = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/gems/gitlab-cng?ref_type=heads#troubleshooting"

        # Ignore metrics events when logging events on deploy failure,
        # these get generated on pod startup due to various reasons like pod not ready and don't affect deployment state
        #
        # @return [Array]
        IGNORED_EVENTS = %w[FailedComputeMetricsReplicas FailedGetResourceMetric].freeze

        # Delete installation
        #
        # @param [String] name
        # @param [Configurations::Cleanup::Base] cleanup_configuration
        # @param [String] timeout
        # @return [void]
        def self.uninstall(name, cleanup_configuration:, timeout:)
          helm = Helm::Client.new
          namespace = cleanup_configuration.namespace

          log("Performing full deployment cleanup", :info, bright: true)
          return log("Helm release '#{name}' not found, skipping", :warn) unless helm.status(name, namespace: namespace)

          Helpers::Spinner.spin("uninstalling helm release '#{name}'") do
            helm.uninstall(name, namespace: namespace, timeout: timeout)

            log("Removing license secret", :info)
            puts cleanup_configuration.kubeclient.delete_resource("secret", LICENSE_SECRET)
          end

          Helpers::Spinner.spin("removing configuration specific objects") do
            cleanup_configuration.run
          end

          Helpers::Spinner.spin("removing namespace '#{namespace}'") do
            puts cleanup_configuration.kubeclient.delete_resource("namespace", namespace)
          end
        end

        def initialize(name, configuration:, namespace:, ci:, gitlab_domain:, timeout:, **args)
          @name = name
          @configuration = configuration
          @namespace = namespace
          @ci = ci
          @gitlab_domain = gitlab_domain
          @timeout = timeout
          @set = args[:set] || []
          @extra_env = args[:env] || []
          @chart_sha = args[:chart_sha]
          @retry_attempts = args[:retry] || 0
          @deployment_attempts = 0
        end

        # Perform deployment with all the additional setup
        #
        # @return [void]
        def create
          log("Creating CNG deployment '#{name}'", :info, bright: true)
          chart_reference = run_pre_deploy_setup
          run_deploy(chart_reference)
          run_post_deploy_setup
        # Exit on error to not duplicate error messages and exit cleanly when kubectl or helm related errors are raised
        rescue Kubectl::Client::Error, Helm::Client::Error
          exit(1)
        end

        # Specific component version values used in CI
        #
        # @return [String]
        def component_version_values
          @component_version_values ||= DefaultValues.component_ci_versions.map { |k, v| "#{k}=#{v}" }
        end

        private

        attr_reader :name,
          :configuration,
          :namespace,
          :ci,
          :set,
          :gitlab_domain,
          :timeout,
          :chart_sha,
          :extra_env,
          :retry_attempts

        alias_method :cli_values, :set

        # Kubectl client instance
        #
        # @return [Kubectl::Client]
        def kubeclient
          @kubeclient ||= Kubectl::Client.new(namespace)
        end

        # Helm client instance
        #
        # @return [Helm::Client]
        def helm
          @helm ||= Helm::Client.new
        end

        # Gitlab license
        #
        # @return [String]
        def license
          @license ||= ENV["QA_EE_LICENSE"] || ENV["EE_LICENSE"]
        end

        # Helm values for license secret
        #
        # @return [Hash]
        def license_values
          return {} unless license

          {
            global: {
              extraEnv: {
                GITLAB_LICENSE_MODE: "test",
                CUSTOMER_PORTAL_URL: "https://customers.staging.gitlab.com"
              }
            },
            gitlab: {
              license: {
                secret: LICENSE_SECRET
              }
            }
          }
        end

        # Additional environment variables for deployment
        #
        # @return [Hash]
        def env_values
          return {} if extra_env.empty?

          env = extra_env.map { |e| e.split("=") }.reject { |e| e.size != 2 }.to_h
          return {} if env.empty?

          {
            global: {
              extraEnv: env
            }
          }
        end

        # Execute pre-deployment setup which consists of:
        #   * chart setup
        #   * namespace and license creation
        #   * optional configuration specific pre-deploy setup
        #
        # @return [String] chart reference
        def run_pre_deploy_setup
          Helpers::Spinner.spin("running pre-deployment setup") do
            chart_reference = helm.add_gitlab_helm_chart(chart_sha)
            create_namespace
            create_license

            configuration.run_pre_deployment_setup

            chart_reference
          end
        end

        # Run helm deployment
        #
        # @param [String] chart_reference
        # @return [void]
        def run_deploy(chart_reference)
          args = ["--atomic"]
          args.push(*component_version_values.flat_map { |v| ["--set", v] }) if ci
          args.push("--set", cli_values.join(",")) unless cli_values.empty?
          values = DefaultValues.common_values(gitlab_domain)
            .deep_merge(license_values)
            .deep_merge(env_values)
            .deep_merge(configuration.values)
            .deep_merge(ResourcePresets.resource_values(ci ? ResourcePresets::HIGH : ResourcePresets::DEFAULT))
            .deep_stringify_keys
            .to_yaml

          Helpers::Spinner.spin("running helm deployment") do
            opts = {
              namespace: namespace,
              timeout: timeout,
              values: values,
              # remove --atomic on last attempt so failed deployment is not removed on failure
              args: @deployment_attempts == retry_attempts ? args.reject { |a| a == "--atomic" } : args
            }
            helm.upgrade(name, chart_reference, **opts)
          rescue Helm::Client::Error => e
            @deployment_attempts += 1
            handle_deploy_failure(e) if @deployment_attempts > retry_attempts

            log("Deployment failed, retrying...", :warn)
            log("Error: #{e}", :warn)
            retry
          end
          log("Deployment successful and app is available via: #{configuration.gitlab_url}", :success, bright: true)
        end

        # Execute post-deployment setup
        #
        # @return [void]
        def run_post_deploy_setup
          Helpers::Spinner.spin("running post-deployment setup") { configuration.run_post_deployment_setup }
        end

        # Create namespace
        #
        # @return [void]
        def create_namespace
          log("Creating namespace '#{namespace}'", :info)
          puts kubeclient.create_namespace
        rescue Kubectl::Client::Error => e
          return log("namespace already exists, skipping", :warn) if e.message.include?("already exists")

          raise(e)
        end

        # Create gitlab license
        #
        # @return [void]
        def create_license
          log("Creating gitlab license secret", :info)
          return log("`QA_EE_LICENSE|EE_LICENSE` variable is not set, skipping", :warn) unless license

          secret = Kubectl::Resources::Secret.new(LICENSE_SECRET, "license", license)
          puts mask_secrets(kubeclient.create_resource(secret), [license, Base64.encode64(license)])
        end

        # Handle helm upgrade failure
        #
        # @param [StandardError] error
        # @return [void]
        def handle_deploy_failure(error)
          log("Helm deployment failed!", :error)
          log("For more information on troubleshooting failures, see: '#{TROUBLESHOOTING_LINK}'", :warn)

          events = get_warning_events
          if events
            log("Following events of Warning type present in cluster:", :warn)
            log(events)
          end

          raise error
        end

        # Get cluster events with warning type
        #
        # @return [String]
        def get_warning_events
          items = JSON.parse(kubeclient.events(json_format: true), symbolize_names: true)[:items]

          events = items
            .select { |item| item[:kind] == "Event" && item[:type] == "Warning" }
            .reject { |item| IGNORED_EVENTS.include?(item[:reason]) }
            .map do |item|
              object = item[:involvedObject]

              {
                **item.slice(:type, :reason),
                name: "#{object[:kind]}/#{object[:name]}",
                message: item[:message]
              }
            end
          return if events.empty?

          JSON.pretty_generate(events)
        end
      end
    end
  end
end

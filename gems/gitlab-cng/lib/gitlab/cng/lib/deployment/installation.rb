# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      class Installation
        include Helpers::Output
        include Helpers::Shell

        LICENSE_SECRET = "gitlab-license"

        def initialize(name, configuration:, namespace:, ci:, set: [])
          @name = name
          @configuration = configuration
          @namespace = namespace
          @ci = ci
          @set = set
          @kubeclient = Kubectl::Client.new(namespace)
        end

        # Perform deployment with all the additional setup
        #
        # @return [void]
        def create
          log("Creating CNG deployment '#{name}' using '#{configuration}' configuration", :info, bright: true)
          run_pre_deploy_setup
        rescue Helpers::Shell::CommandFailure
          exit(1)
        end

        private

        attr_reader :name, :configuration, :namespace, :ci, :set, :kubeclient
        alias_method :cli_values, :set

        # Configuration class instance
        #
        # @return [Configuration::Base]
        def config_instance
          @config_instance ||= Configurations.const_get(configuration.capitalize, false).new(namespace, kubeclient)
        end

        # Execute pre-deployment setup
        #
        # @return [void]
        def run_pre_deploy_setup
          Helpers::Spinner.spin("running pre-deployment setup") do
            add_helm_chart
            update_helm_chart_repo
            create_namespace
            create_license

            config_instance.run_pre_deployment_setup
          end
        end

        # Execute post-deployment setup
        #
        # @return [void]
        def run_post_deploy_setup
          Helpers::Spinner.spin("running post-deployment setup") do
            config_instance.run_pre_deployment_setup
          end
        end

        # Add helm chart repo
        #
        # @return [void]
        def add_helm_chart
          log("Adding gitlab helm chart", :info)
          puts run_helm_cmd(%w[repo add gitlab https://charts.gitlab.io])
        rescue Helpers::Shell::CommandFailure => e
          return log("helm repo already exists, skipping", :warn) if e.message.include?("already exists")

          raise(e)
        end

        # Update helm chart repo
        #
        # @return [void]
        def update_helm_chart_repo
          log("Updating gitlab helm chart repo", :info)
          puts run_helm_cmd(%w[repo update gitlab])
        end

        # Create namespace
        #
        # @return [void]
        def create_namespace
          log("Creating namespace '#{namespace}'", :info)
          puts kubeclient.create_namespace
        rescue StandardError => e
          return log("namespace already exists, skipping", :warn) if e.message.include?("already exists")

          raise(e)
        end

        # Create gitlab license
        #
        # @return [void]
        def create_license
          license = ENV["QA_EE_LICENSE"]

          log("Creating gitlab license secret", :info)
          return log("`QA_EE_LICENSE` variable is not set, skipping", :warn) unless license

          secret = Kubectl::Resources::Secret.new(LICENSE_SECRET, "license", ENV["QA_EE_LICENSE"])
          puts mask_secrets(kubeclient.create_resource(secret), [license, Base64.encode64(license)])
        end

        # Run helm command
        #
        # @param [Array] cmd
        # @return [String]
        def run_helm_cmd(cmd)
          execute_shell(["helm", *cmd])
        end
      end
    end
  end
end

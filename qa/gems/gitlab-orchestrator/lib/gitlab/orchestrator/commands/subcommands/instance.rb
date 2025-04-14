# frozen_string_literal: true

require "socket"

module Gitlab
  module Orchestrator
    module Commands
      module Subcommands
        # Different instance type subcommands
        #
        # Each public method defines a specific instance type.
        # Each instance method must call {Instance::Installation#create} where installation instance is initialized
        #   with appropriate configuration class which encapsulates optional instance hooks and specific configuration
        #
        class Instance < Command
          DEFAULT_CONTAINER_NAME = "gitlab"
          DEFAULT_IMAGE = "gitlab/gitlab-ee:latest"

          class << self
            # Add common instance options for each instance command defined as public method
            #
            # @param [String] name
            # @return [void]
            def method_added(name)
              option :ci,
                desc: "Use CI specific configuration",
                default: false,
                type: :boolean
              option :timeout,
                desc: "Timeout for instance creation",
                default: "10m",
                type: :string
              option :env,
                desc: "Extra environment variables to set for containers " \
                  "(can specify multiple or separate values with commas: env1=val1,env2=val2)",
                type: :string,
                repeatable: true,
                aliases: "-e"
              option :retry,
                desc: "Max number of retries for failed instance creation",
                default: 0,
                type: :numeric

              super
            end
          end

          desc "gitlab [NAME]", "Create GitLab container instance in Docker where NAME is container name. " \
            "Default: #{DEFAULT_CONTAINER_NAME}"
          option :image,
            desc: "Docker image to use for GitLab",
            type: :string,
            default: DEFAULT_IMAGE
          option :gitlab_domain,
            desc: "Domain for deployed app, defaults to localhost",
            type: :string,
            default: "localhost"
          option :admin_password,
            desc: "Admin password for gitlab, defaults to password commonly used across development environments",
            type: :string,
            default: "5iveL!fe"
          option :host_http_port,
            desc: "Host HTTP port for gitlab",
            type: :numeric,
            default: 8080
          option :print_config_args,
            desc: "Print all CI specific component values and configuration arguments." \
              "Useful for reproducing CI instances. Only valid with --ci flag.",
            type: :boolean,
            default: false
          def gitlab(name = DEFAULT_CONTAINER_NAME)
            return print_config_args("gitlab") if options[:print_config_args] && options[:ci]

            configuration_args = symbolized_options.slice(
              :image,
              :gitlab_domain,
              :admin_password,
              :host_http_port,
              :ci
            )

            installation(name, Orchestrator::Instance::Configurations::Gitlab.new(**configuration_args)).create
          end

          private

          # Installation instance
          #
          # @param [String] name
          # @param [Instance::Configurations::Base] configuration
          # @return [Instance::Installation]
          def installation(name, configuration)
            Orchestrator::Instance::Installation.new(
              name, configuration: configuration,
              **symbolized_options.slice(:ci, :gitlab_domain, :timeout, :env, :retry)
            )
          end

          # Print example of instance configuration arguments and all CI component arguments
          #
          # @param [String] configuration instance configuration name
          # @return [void]
          def print_config_args(configuration)
            cmd = ["orchestrator", "create", "instance", configuration]
            cmd.push(*options[:env].flat_map { |opt| ["--env", opt] }) if options[:env]

            log("Received --print-config-args option, printing example of all instance arguments!", :warn)
            log("To reproduce CI instance, run orchestrator with following arguments:")
            log("  #{cmd.join(' ')}")
          end

          # Populate options with default gitlab domain if missing
          #
          # @return [Hash]
          def symbolized_options
            @symbolized_options ||= super.tap do |opts|
              next unless opts[:gitlab_domain].nil?

              opts.merge!({ gitlab_domain: "localhost" })
            end
          end
        end
      end
    end
  end
end

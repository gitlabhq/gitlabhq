# frozen_string_literal: true

require "socket"

module Gitlab
  module Cng
    module Commands
      module Subcommands
        # Different deployment type subcommands
        #
        # Each public method defines a specific deployment type.
        # Each deployment method must call {Deployment::Installaton#create} where installation instance is initialized
        #   with appropriate configuration class which encapsulates optional deployment hooks and specific helm values
        #
        class Deployment < Command
          DEFAULT_HELM_RELEASE_NAME = "gitlab"

          class << self
            # Add common deployment options for each deployment command defined as public method
            #
            # @param [String] name
            # @return [void]
            def method_added(name)
              option :namespace,
                desc: "Deployment namespace",
                default: "gitlab",
                type: :string,
                aliases: "-n"
              option :set,
                desc: "Optional helm chart values " \
                  "(can specify multiple or separate values with commas: key1=val1,key2=val2)",
                type: :string,
                repeatable: true
              option :ci,
                desc: "Use CI specific configuration",
                default: false,
                type: :boolean
              option :timeout,
                desc: "Timeout for deployment",
                default: "10m",
                type: :string
              option :chart_sha,
                desc: "Specific sha of GitLab chart repository, latest release version is used by default. " \
                  "Requires 'tar' executable to be installed.",
                type: :string
              option :env,
                desc: "Extra environment variables to set for rails containers " \
                  "(can specify multiple or separate values with commas: env1=val1,env2=val2)",
                type: :string,
                repeatable: true,
                aliases: "-e"
              option :retry,
                desc: "Max number of retries for failed deployment",
                default: 0,
                type: :numeric

              super
            end
          end

          desc "kind [NAME]", "Create CNG deployment against local kind k8s cluster where NAME is helm release name. " \
            "Default: #{DEFAULT_HELM_RELEASE_NAME}"
          option :create_cluster,
            desc: "Create kind cluster for local deployments before creating deployment",
            type: :boolean,
            default: true
          option :docker_hostname,
            desc: "Custom docker hostname if remote docker instance is used, like docker-in-docker, " \
              "only applicable when --create-cluster is true",
            type: :string
          option :gitlab_domain,
            desc: "Domain for deployed app, default to (your host IP).nip.io",
            type: :string
          option :admin_password,
            desc: "Admin password for gitlab, defaults to password commonly used across development environments",
            type: :string,
            default: "5iveL!fe"
          option :admin_token,
            desc: "Admin token for gitlab, defaults to value used in gitlab development seed data",
            type: :string,
            default: "ypCa3Dzb23o5nvsixwPA"
          option :host_http_port,
            desc: "Host HTTP port for gitlab",
            type: :numeric,
            default: 80
          option :host_ssh_port,
            desc: "Host ssh port for gitlab",
            type: :numeric,
            default: 22
          option :host_registry_port,
            desc: "Host registry port for gitlab",
            type: :numeric,
            default: 5000
          option :print_deploy_args,
            desc: "Print all CI specific component helm values and deployment arguments." \
              "Useful for reproducing CI deployments. Only valid with --ci flag.",
            type: :boolean,
            default: false
          def kind(name = DEFAULT_HELM_RELEASE_NAME)
            return print_deploy_args("kind") if options[:print_deploy_args] && options[:ci]

            if options[:create_cluster]
              Kind::Cluster.new(**symbolized_options.slice(
                :docker_hostname, :ci, :host_http_port, :host_ssh_port, :host_registry_port
              )).create
            end

            configuration_args = symbolized_options.slice(
              :namespace,
              :ci,
              :gitlab_domain,
              :admin_password,
              :admin_token,
              :host_http_port,
              :host_ssh_port,
              :host_registry_port
            )

            installation(name, Cng::Deployment::Configurations::Kind.new(**configuration_args)).create
          end

          private

          # Installation instance
          #
          # @param [String] name
          # @param [Deployment::Configurations::Base] configuration
          # @return [Deployment::Installation]
          def installation(name, configuration)
            Cng::Deployment::Installation.new(
              name, configuration: configuration,
              **symbolized_options.slice(:namespace, :set, :ci, :gitlab_domain, :timeout, :chart_sha, :env, :retry)
            )
          end

          # Print example of deployment arguments and all CI component arguments
          #
          # @param [String] configuration deployment configuration name
          # @return [void]
          def print_deploy_args(configuration)
            ci_components = Cng::Deployment::DefaultValues.component_ci_versions.flat_map do |component, version|
              ["--set", "#{component}=#{version}"]
            end
            cmd = ["cng", "create", "deployment", configuration, *ci_components]
            cmd.push(*options[:set].flat_map { |opt| ["--set", opt] }) if options[:set]
            cmd.push(*options[:env].flat_map { |opt| ["--env", opt] }) if options[:env]
            cmd.push("--chart-sha", options[:chart_sha]) if options[:chart_sha]

            log("Received --print-deploy-args option, printing example of all deployment arguments!", :warn)
            log("To reproduce CI deployment, run cng with following arguments:")
            log("  #{cmd.join(' ')}")
          end

          # Populate options with default gitlab domain if missing
          #
          # @return [Hash]
          def symbolized_options
            @symbolized_options ||= super.tap do |opts|
              next unless opts[:gitlab_domain].nil?

              # merge default option lazily to not fetch ip_address_list every time class is loaded
              opts.merge!({ gitlab_domain: "#{Socket.ip_address_list.detect(&:ipv4_private?).ip_address}.nip.io" })
            end
          end
        end
      end
    end
  end
end

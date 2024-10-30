# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Destroy command consisting of cleanup for cluster and deployments
      #
      class Destroy < Command
        desc "cluster", "Destroy kind cluster created for kind type deployments"
        def cluster
          delete = TTY::Prompt.new.yes?("Are you sure you want to delete cluster #{Kind::Cluster::CLUSTER_NAME}?")
          return unless delete

          Kind::Cluster.destroy
        end

        desc "deployment [NAME]", "Destroy specific deployment and all it's resources, " \
          "where NAME is helm relase name. " \
          "Default: #{Subcommands::Deployment::DEFAULT_HELM_RELEASE_NAME}"
        option :type,
          desc: "Specific deployment configuration type name",
          type: :string,
          enum: Subcommands::Deployment.commands.keys.reject { |c| c == "help" }
        option :namespace,
          desc: "Deployment namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :timeout,
          desc: "Timeout for helm release uninstall",
          default: "10m",
          type: :string
        option :with_cluster,
          desc: "Destroy kind cluster that was created for the deployment, " \
            "only applicable for deployment type 'kind'",
          default: false,
          type: :boolean
        def deployment(name = Subcommands::Deployment::DEFAULT_HELM_RELEASE_NAME)
          prompt = TTY::Prompt.new
          delete = prompt.yes?("Are you sure you want to delete deployment '#{name}'?")
          return unless delete

          type = options[:type] || prompt.select(
            "Select deployment configuration type:", Subcommands::Deployment.commands.keys.reject { |c| c == "help" }
          )
          cleanup_configuration = Deployment::Configurations::Cleanup
            .const_get(type.capitalize, false)
            .new(options[:namespace])

          Deployment::Installation.uninstall(
            name,
            cleanup_configuration: cleanup_configuration,
            timeout: options[:timeout]
          )

          Kind::Cluster.destroy if options[:with_cluster]
        end
      end
    end
  end
end

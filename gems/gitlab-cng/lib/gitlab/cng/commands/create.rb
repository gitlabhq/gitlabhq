# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Create command composed of subcommands that create various resources needed for CNG deployment
      #
      class Create < Command
        # @return [Array] configurations that are used for kind cluster deployments
        KIND_CLUSTER_CONFIGURATIONS = %w[kind].freeze

        desc "cluster", "Create kind cluster for local deployments"
        option :name,
          desc: "Cluster name",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :ci,
          desc: "Use CI specific configuration",
          default: false,
          type: :boolean,
          aliases: "-c"
        option :docker_hostname,
          desc: "Custom docker hostname if remote docker instance is used, like docker-in-docker",
          type: :string,
          aliases: "-d"
        def cluster
          Kind::Cluster.new(**symbolized_options).create
        end

        desc "deployment [NAME]", "Create CNG deployment from official GitLab Helm chart"
        long_desc <<~LONGDESC
          This command installs a GitLab chart archive and performs all additional pre-install and post-install setup.
          Argument NAME is helm install name and defaults to "gitlab".
          Deployment has several optional environment variables it can read before performing chart install:
            QA_EE_LICENSE|EE_LICENSE - gitlab test license, if present, will be added to deployment,
        LONGDESC
        option :configuration,
          desc: "Deployment configuration",
          default: "kind",
          type: :string,
          aliases: "-c",
          enum: ["kind"]
        option :namespace,
          desc: "Deployment namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :set,
          desc: "Optional helm chart values (can specify multiple or separate values with commas: key1=val1,key2=val2)",
          type: :string,
          repeatable: true
        option :ci,
          desc: "Use CI specific configuration",
          default: false,
          type: :boolean
        option :gitlab_domain,
          desc: "Domain for deployed app. Defaults to (your host IP).nip.io",
          type: :string
        option :with_cluster,
          desc: "Create kind cluster for local deployments. \
            Only valid for configurations designed to run against local kind cluster",
          type: :boolean
        def deployment(name = "gitlab")
          if options[:with_cluster] && KIND_CLUSTER_CONFIGURATIONS.include?(options[:configuration])
            invoke :cluster, [], ci: options[:ci]
          end

          Deployment::Installation
            .new(name, **symbolized_options.slice(:configuration, :namespace, :set, :ci, :gitlab_domain))
            .create
        end
      end
    end
  end
end
